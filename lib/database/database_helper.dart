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

    // جدول جهات الاتصال (العملاء والموردين)
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // جدول حركات الصندوق
    await db.execute('''
      CREATE TABLE cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id)
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id)
      )
    ''');
  }

  // ==========================================
  // 1. دوال المنتجات (Products)
  // ==========================================

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // ==========================================
  // 2. دوال جهات الاتصال (Contacts)
  // ==========================================

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts');
  }

  Future<int> updateContactBalance(int contactId, double adjustment) async {
    final db = await instance.database;
    return await db.rawUpdate(
      'UPDATE contacts SET balance = balance + ? WHERE id = ?',
      [adjustment, contactId],
    );
  }

  // ==========================================
  // 3. دوال حركات الصندوق (Cash Transactions)
  // ==========================================

  Future<int> addCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('cash_transactions', row);
  }

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query(
      'cash_transactions',
      where: 'date LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    final id = row['id'];
    return await db.update(
      'cash_transactions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCashTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cash_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // 4. دوال الفواتير (Invoices)
  // ==========================================

  Future<int> addInvoice(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('invoices', row);
  }

  // ==========================================
  // إغلاق قاعدة البيانات
  // ==========================================

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
