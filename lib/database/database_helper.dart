import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database_v3.db');
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
    // 1. جدول العملاء والموردين
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance_syr REAL DEFAULT 0.0,
        balance_usd REAL DEFAULT 0.0,
        balance REAL DEFAULT 0.0
      )
    ''');

    // 2. جدول المنتجات والمواد
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        retail_price REAL DEFAULT 0.0,
        wholesale_price REAL DEFAULT 0.0,
        cost_price REAL DEFAULT 0.0,
        buy_price REAL DEFAULT 0.0,
        price REAL DEFAULT 0.0,
        quantity REAL DEFAULT 0.0,
        stock_quantity REAL DEFAULT 0.0
      )
    ''');

    // 3. جدول الفواتير
    await db.execute('''
      CREATE TABLE sales_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_name TEXT,
        type TEXT,
        date TEXT,
        subtotal REAL,
        discount REAL,
        total_amount REAL,
        paid_amount REAL,
        remaining_amount REAL
      )
    ''');

    // 4. جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        product_id INTEGER,
        product_name TEXT,
        quantity REAL,
        unit_price REAL,
        total REAL
      )
    ''');
  }

  Future<List<ContactModel>> getContacts() async {
    final db = await instance.database;
    final result = await db.query('contacts');
    return result.map((json) => ContactModel.fromMap(json)).toList();
  }

  Future<int> insertContact(ContactModel contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact.toMap());
  }
}
