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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. جدول المنتجات (يدعم أسعار المفرق، الجملة، والتكلفة)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        retail_price REAL NOT NULL,
        wholesale_price REAL NOT NULL,
        cost_price REAL NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL
      )
    ''');

    // 2. جدول العملاء/الأطراف (يدعم الرصيد بالليرة والدولار)
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance_syr REAL NOT NULL DEFAULT 0.0,
        balance_usd REAL NOT NULL DEFAULT 0.0,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 3. جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER,
        currency TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        net_total REAL NOT NULL,
        paid_amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. جدول تفاصيل الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 5. جدول دفتر الصندوق (journal_entries)
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // --- عمليات الأطراف / العملاء ---

  Future<List<ContactModel>> getContacts() async {
    final db = await database;
    final result = await db.query('contacts');
    return result.map((json) => ContactModel.fromJson(json)).toList();
  }

  Future<List<ContactModel>> searchContacts(String query) async {
    final db = await database;
    final result = await db.query(
      'contacts',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((json) => ContactModel.fromJson(json)).toList();
  }

  Future<int> insertContact(ContactModel contact) async {
    final db = await database;
    return await db.insert('contacts', contact.toJson());
  }

  Future<int> updateContact(ContactModel contact) async {
    final db = await database;
    return await db.update(
      'contacts',
      contact.toJson(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- عمليات المنتجات ---

  Future<List<Product>> getProducts() async {
    final db = await database;
    final result = await db.query('products');
    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR barcode = ?',
      whereArgs: ['%$query%', query],
    );
    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toJson());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- عمليات الفواتير والحفظ التفصيلي ---

  Future<void> saveInvoiceWithDetails(
    Map<String, dynamic> invoiceData,
    List<dynamic> items,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. إدراج رأس الفاتورة
      int invoiceId = await txn.insert('invoices', invoiceData);

      // 2. إدراج بنود الفاتورة وتحديث كميات المواد
      for (var item in items) {
        final Map<String, dynamic> itemMap = {
          'invoice_id': invoiceId,
          'product_id': item.product.id,
          'price': item.price,
          'quantity': item.quantity,
          'total': item.total,
        };
        await txn.insert('invoice_items', itemMap);

        // تحديث الكمية المتبقية في جدول المنتجات
        if (item.product.id != null) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity - ? WHERE id = ?',
            [item.quantity, item.product.id],
          );
        }
      }

      // 3. تحديث رصيد العميل بناءً على العملة
      if (invoiceData['party_id'] != null) {
        double remaining = (invoiceData['remaining_amount'] as num).toDouble();
        String currency = invoiceData['currency'] ?? 'ليرة سورية';

        if (currency.contains('دولار') || currency.contains(r'$')) {
          await txn.rawUpdate(
            'UPDATE contacts SET balance_usd = balance_usd + ? WHERE id = ?',
            [remaining, invoiceData['party_id']],
          );
        } else {
          await txn.rawUpdate(
            'UPDATE contacts SET balance_syr = balance_syr + ?, balance = balance + ? WHERE id = ?',
            [remaining, remaining, invoiceData['party_id']],
          );
        }
      }
    });
  }

  // دالة توافق سابقة
  Future<void> insertInvoice(Map<String, dynamic> invoiceData, List items) async {
    await saveInvoiceWithDetails(invoiceData, items);
  }
}
