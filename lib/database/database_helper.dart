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
      version: 3, // رفع رقم الإصدار لدعم أسعار المنتجات المتقدمة
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        purchase_price REAL NOT NULL DEFAULT 0.0,
        price REAL NOT NULL DEFAULT 0.0, -- سعر المفرق
        semi_wholesale_price REAL NOT NULL DEFAULT 0.0, -- سعر نصف الجملة
        wholesale_price REAL NOT NULL DEFAULT 0.0, -- سعر الجملة
        quantity REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

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

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT NOT NULL,
        subtotal REAL NOT NULL DEFAULT 0.0,
        discount REAL NOT NULL DEFAULT 0.0,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN purchase_price REAL NOT NULL DEFAULT 0.0');
        await db.execute('ALTER TABLE products ADD COLUMN semi_wholesale_price REAL NOT NULL DEFAULT 0.0');
        await db.execute('ALTER TABLE products ADD COLUMN wholesale_price REAL NOT NULL DEFAULT 0.0');
      } catch (_) {}
    }
  }

  // ==========================================
  // إدارة المنتجات (Products)
  // ==========================================

  Future<int> insertProduct(
    dynamic data, {
    String? name,
    double? purchasePrice,
    double? price,
    double? semiWholesalePrice,
    double? wholesalePrice,
    double? quantity,
  }) async {
    final db = await instance.database;
    if (data is Map<String, dynamic>) {
      return await db.insert('products', data);
    }
    return await db.insert('products', {
      'name': name ?? '',
      'purchase_price': purchasePrice ?? 0.0,
      'price': price ?? 0.0,
      'semi_wholesale_price': semiWholesalePrice ?? 0.0,
      'wholesale_price': wholesalePrice ?? 0.0,
      'quantity': quantity ?? 0.0,
    });
  }

  Future<int> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  // ==========================================
  // حركة المادة (Product Movement Report)
  // ==========================================

  Future<List<Map<String, dynamic>>> getProductMovements(int productId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        ii.id AS item_id,
        ii.quantity,
        ii.unit_price,
        ii.total,
        i.id AS invoice_id,
        i.type AS invoice_type,
        i.date,
        i.contact_name,
        i.contact_id
      FROM invoice_items ii
      INNER JOIN invoices i ON ii.invoice_id = i.id
      WHERE ii.product_id = ?
      ORDER BY i.id DESC
    ''', [productId]);
  }

  // جلب البيانات الأخرى
  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'id DESC');
  }
}
