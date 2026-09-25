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
      version: 2, // رفع الإصدار للترقية التلقائية
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ==========================================
  // إنشاء كافة جداول قاعدة البيانات بالكامل
  // ==========================================
  Future _createDB(Database db, int version) async {
    // 1. جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        buy_price REAL DEFAULT 0.0,
        retail_price REAL DEFAULT 0.0,
        half_wholesale_price REAL DEFAULT 0.0,
        wholesale_price REAL DEFAULT 0.0,
        quantity REAL DEFAULT 0.0
      )
    ''');

    // 2. جدول العملاء والموردين
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT,
        balance REAL DEFAULT 0.0
      )
    ''');

    // 3. جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        contact_id INTEGER,
        contact_name TEXT,
        total_amount REAL DEFAULT 0.0,
        discount REAL DEFAULT 0.0,
        net_amount REAL DEFAULT 0.0,
        paid_amount REAL DEFAULT 0.0,
        remaining_amount REAL DEFAULT 0.0,
        date TEXT,
        FOREIGN KEY (contact_id) REFERENCES contacts (id)
      )
    ''');

    // 4. جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT,
        quantity REAL DEFAULT 0.0,
        price REAL DEFAULT 0.0,
        total REAL DEFAULT 0.0,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // 5. جدول حركة الصندوق والمقبوضات/المدفوعات
    await db.execute('''
      CREATE TABLE cash_journal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL DEFAULT 0.0,
        description TEXT,
        contact_id INTEGER,
        date TEXT,
        FOREIGN KEY (contact_id) REFERENCES contacts (id)
      )
    ''');
  }

  // ==========================================
  // دالة الترقية عند تغيير هيكلية قواعد البيانات
  // ==========================================
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة حقل نصف الجملة للنسخ السابقة التي تجري على الأجهزة
      await db.execute('ALTER TABLE products ADD COLUMN half_wholesale_price REAL DEFAULT 0.0');
    }
  }

  // ==========================================
  // عمليات المنتجات (Products Operations)
  // ==========================================
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // عمليات العملاء والموردين (Contacts Operations)
  // ==========================================
  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'id DESC');
  }

  Future<int> updateContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.update('contacts', contact, where: 'id = ?', whereArgs: [contact['id']]);
  }

  // ==========================================
  // عمليات الفواتير (Invoices Operations)
  // ==========================================
  Future<int> insertInvoice(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    int invoiceId = 0;

    await db.transaction((txn) async {
      invoiceId = await txn.insert('invoices', invoice);
      for (var item in items) {
        item['invoice_id'] = invoiceId;
        await txn.insert('invoice_items', item);
      }
    });

    return invoiceId;
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  // ==========================================
  // عمليات حركة الصندوق (Cash Journal Operations)
  // ==========================================
  Future<int> insertCashJournal(Map<String, dynamic> entry) async {
    final db = await instance.database;
    return await db.insert('cash_journal', entry);
  }

  Future<List<Map<String, dynamic>>> getCashJournal() async {
    final db = await instance.database;
    return await db.query('cash_journal', orderBy: 'id DESC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
