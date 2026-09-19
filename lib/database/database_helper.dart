import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
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

  Future<void> _createDB(Database db, int version) async {
    // جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // جدول الجهات / العملاء
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT
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
        date TEXT NOT NULL
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT,
        type TEXT NOT NULL,
        total_amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // --- دوال المنتجات (Products) ---
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // --- دوال الجهات / العملاء (Contacts) ---
  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts');
  }

  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact);
  }

  // --- دوال الصندوق (Cash Transactions) ---
  Future<int> addCashTransaction({
    int? contactId,
    required String contactName,
    required String type,
    required double amount,
    String? notes,
    required String date,
  }) async {
    final db = await instance.database;
    return await db.insert('cash_transactions', {
      'contact_id': contactId,
      'contact_name': contactName,
      'type': type,
      'amount': amount,
      'notes': notes,
      'date': date,
    });
  }

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query(
      'cash_transactions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
  }

  // --- دوال الفواتير (Invoices) ---
  Future<int> addInvoice({
    int? contactId,
    required String contactName,
    required String type,
    required double totalAmount,
    required String date,
    List<Map<String, dynamic>>? items,
  }) async {
    final db = await instance.database;
    return await db.insert('invoices', {
      'contact_id': contactId,
      'contact_name': contactName,
      'type': type,
      'total_amount': totalAmount,
      'date': date,
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
