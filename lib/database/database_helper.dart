import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('store_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        buy_price REAL,
        sell_price REAL,
        quantity REAL
      )
    ''');

    // جدول الجهات (العملاء والموردين)
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL DEFAULT 0.0,
        balance_syr REAL DEFAULT 0.0
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE sales_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        contact_id INTEGER,
        contact_name TEXT,
        subtotal REAL,
        discount REAL,
        total_amount REAL,
        paid_amount REAL,
        remaining_amount REAL,
        date TEXT
      )
    ''');

    // جدول حركات الصندوق
    await db.execute('''
      CREATE TABLE cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        date TEXT
      )
    ''');
  }

  // --- عمليات المنتجات ---
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // --- عمليات الجهات / العملاء ---
  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts');
  }

  // --- عمليات الفواتير ---
  Future<int> addInvoice({
    required String type,
    required int? contactId,
    required String contactName,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double total,
    required double paid,
    required String date,
  }) async {
    final db = await instance.database;
    
    // 1. إضافة الفاتورة إلى جدول الفواتير
    final id = await db.insert('sales_invoices', {
      'type': type,
      'contact_id': contactId,
      'contact_name': contactName,
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': total,
      'paid_amount': paid,
      'remaining_amount': total - paid,
      'date': date,
    });

    // 2. تحديث رصيد العميل بناءً على الجزء المتبقي غير المدفوع
    if (contactId != null) {
      final double remaining = total - paid;
      if (remaining != 0) {
        final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [contactId]);
        if (contactResult.isNotEmpty) {
          double currentBalance = ((contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0) as num).toDouble();
          
          if (type == 'sale') {
            currentBalance += remaining; // المبيعات الآجلة تزيد الدين
          } else {
            currentBalance -= remaining; // المشتريات الآجلة تنقص الدين/تزيد حساب المورد
          }

          await db.update(
            'contacts',
            {
              'balance_syr': currentBalance,
              'balance': currentBalance,
            },
            where: 'id = ?',
            whereArgs: [contactId],
          );
        }
      }
    }

    return id;
  }

  // --- عمليات حركة الصندوق ---
  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query('cash_transactions', where: 'date = ?', whereArgs: [date], orderBy: 'id DESC');
  }

  Future<int> addCashTransaction({
    required int? contactId,
    required String contactName,
    required String type,
    required double amount,
    required String notes,
    required String date,
  }) async {
    final db = await instance.database;

    // 1. تسليط الحركة في الصندوق
    final id = await db.insert('cash_transactions', {
      'contact_id': contactId,
      'contact_name': contactName,
      'type': type,
      'amount': amount,
      'notes': notes,
      'date': date,
    });

    // 2. تحديث رصيد العميل تلقائياً
    if (contactId != null) {
      final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [contactId]);
      if (contactResult.isNotEmpty) {
        double currentBalance = ((contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0) as num).toDouble();

        if (type == 'income') {
          currentBalance -= amount; // القبض ينقص دين العميل
        } else {
          currentBalance += amount; // الدفع يزيد حساب العميل
        }

        await db.update(
          'contacts',
          {
            'balance_syr': currentBalance,
            'balance': currentBalance,
          },
          where: 'id = ?',
          whereArgs: [contactId],
        );
      }
    }

    return id;
  }
}
