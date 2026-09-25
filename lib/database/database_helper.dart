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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT,
        balance REAL DEFAULT 0.0
      )
    ''');

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

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN half_wholesale_price REAL DEFAULT 0.0');
    }
  }

  // ==========================================
  // 1. إدارة المنتجات وحركاتها
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
    return await db.update('products', product, where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // دالة جلب كشف حركة المادة
  Future<List<Map<String, dynamic>>> getProductMovements(int productId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        ii.id,
        ii.invoice_id,
        ii.quantity,
        ii.price,
        ii.total,
        i.type AS invoice_type,
        i.contact_name,
        i.date
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE ii.product_id = ?
      ORDER BY i.date DESC
    ''', [productId]);
  }

  // ==========================================
  // 2. الحسابات والعملاء
  // ==========================================
  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'id DESC');
  }

  Future<int> updateContactBalance(int? contactId, double amount) async {
    if (contactId == null) return 0;
    final db = await instance.database;
    return await db.rawUpdate(
      'UPDATE contacts SET balance = balance + ? WHERE id = ?',
      [amount, contactId],
    );
  }

  // ==========================================
  // 3. حركات الصندوق
  // ==========================================
  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query('cash_journal', where: 'date LIKE ?', whereArgs: ['$date%'], orderBy: 'id DESC');
  }

  Future<int> addCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('cash_journal', row);
  }

  Future<int> updateCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('cash_journal', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteCashTransaction(int transactionId) async {
    final db = await instance.database;
    return await db.delete('cash_journal', where: 'id = ?', whereArgs: [transactionId]);
  }

  // ==========================================
  // 4. الفواتير والتدوير السنوي
  // ==========================================
  Future<int> addFullInvoice(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
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

  Future<void> updateFullInvoice(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      await txn.update('invoices', invoice, where: 'id = ?', whereArgs: [invoice['id']]);
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoice['id']]);

      for (var item in items) {
        item['invoice_id'] = invoice['id'];
        await txn.insert('invoice_items', item);
      }
    });
  }

  // دالة التدوير وإغلاق السنة المالية
  Future<bool> executeFiscalYearRollover(String newYear) async {
    final db = await instance.database;
    try {
      await db.transaction((txn) async {
        // تصفير الفواتير وحركات الصندوق للسنة القديمة وتدوير الأرصدة
        await txn.delete('invoices');
        await txn.delete('invoice_items');
        await txn.delete('cash_journal');
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
