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
      version: 2, // ترقية إصدار قاعدة البيانات لدعم الأعمدة الجديدة
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // إنشاء جدول المنتجات بالهيكلية الكاملة لمنع استثناءات الأعمدة المفقودة والسعر الـ null
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        retail_price REAL,
        wholesale_price REAL,
        cost_price REAL,
        buy_price REAL,
        price REAL,
        quantity REAL,
        stock_quantity REAL,
        category TEXT
      )
    ''');

    // إنشاء جدول العملاء والموردين
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL DEFAULT 0.0,
        balance_syr REAL DEFAULT 0.0
      )
    ''');

    // إنشاء جدول الفواتير
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

    // إنشاء جدول حركات الصندوق
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

  // معالجة التحديث التلقائي للجداول عند ترفيع نسخة قاعدة البيانات
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة الأعمدة الناقصة لجدول المنتجات
      final tableInfo = await db.rawQuery("PRAGMA table_info(products)");
      final existingColumns = tableInfo.map((c) => c['name'] as String).toList();

      if (!existingColumns.contains('barcode')) {
        await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
      }
      if (!existingColumns.contains('retail_price')) {
        await db.execute('ALTER TABLE products ADD COLUMN retail_price REAL');
      }
      if (!existingColumns.contains('wholesale_price')) {
        await db.execute('ALTER TABLE products ADD COLUMN wholesale_price REAL');
      }
      if (!existingColumns.contains('cost_price')) {
        await db.execute('ALTER TABLE products ADD COLUMN cost_price REAL');
      }
      if (!existingColumns.contains('price')) {
        await db.execute('ALTER TABLE products ADD COLUMN price REAL');
      }
      if (!existingColumns.contains('stock_quantity')) {
        await db.execute('ALTER TABLE products ADD COLUMN stock_quantity REAL');
      }
      if (!existingColumns.contains('category')) {
        await db.execute('ALTER TABLE products ADD COLUMN category TEXT');
      }
    }
  }

  // --- عمليات المنتجات ---
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // إدخال المنتج بمرونة تقبل Map أو كائن Product لتفادي أخطاء التجميع
  Future<int> insertProduct(dynamic product) async {
    final db = await instance.database;
    if (product is Map<String, dynamic>) {
      return await db.insert('products', product);
    } else {
      // تحويل الكائن تلقائياً عبر toMap() إذا كان كائن نموذج Product
      return await db.insert('products', (product as dynamic).toMap());
    }
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

    // تحديث رصيد الحساب المتبقي تلقائياً لدى العميل/المورد
    if (contactId != null) {
      final double remaining = total - paid;
      if (remaining != 0) {
        final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [contactId]);
        if (contactResult.isNotEmpty) {
          double currentBalance = ((contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0) as num).toDouble();
          
          if (type == 'sale') {
            currentBalance += remaining;
          } else {
            currentBalance -= remaining;
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

    final id = await db.insert('cash_transactions', {
      'contact_id': contactId,
      'contact_name': contactName,
      'type': type,
      'amount': amount,
      'notes': notes,
      'date': date,
    });

    if (contactId != null) {
      final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [contactId]);
      if (contactResult.isNotEmpty) {
        double currentBalance = ((contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0) as num).toDouble();

        if (type == 'income') {
          currentBalance -= amount;
        } else {
          currentBalance += amount;
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
