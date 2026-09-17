import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/contact_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('magd_store.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3, // تم رفع الإصدار إلى 3 لاستيعاب التعديلات الجديدة
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        retail_price REAL,
        wholesale_price REAL,
        cost_price REAL,
        buy_price REAL DEFAULT 0.0,
        price REAL,
        quantity REAL,
        stock_quantity REAL
      )
    ''');

    // 2. جدول الحسابات / العملاء
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        balance REAL DEFAULT 0.0,
        balance_syr REAL DEFAULT 0.0,
        balance_usd REAL DEFAULT 0.0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN buy_price REAL DEFAULT 0.0');
    }
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE contacts ADD COLUMN balance_syr REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE contacts ADD COLUMN balance_usd REAL DEFAULT 0.0');
    }
  }

  // --- دوال الحسابات والعملاء (Contacts) ---

  Future<int> insertContact(Contact contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<List<Contact>> getContacts() async {
    final db = await instance.database;
    final result = await db.query('contacts');
    return result.map((json) => Contact.fromMap(json)).toList();
  }

  Future<int> updateContact(Contact contact) async {
    final db = await instance.database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await instance.database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
