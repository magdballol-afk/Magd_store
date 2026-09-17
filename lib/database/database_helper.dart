import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/contact_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // منشئ افتراضي لضمان التوافق مع DatabaseHelper()
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
      version: 2, // تم رفع الإصدار لتفعيل التحديث الآلي (onUpgrade)
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. جدول المنتجات (يدعم أسعار المفرق، الجملة، الشراء والتكلفة)
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
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة العمود المفقود buy_price لقواعد البيانات الموجودة على الأجهزة سابقاً
      await db.execute('ALTER TABLE products ADD COLUMN buy_price REAL DEFAULT 0.0');
    }
  }
}
