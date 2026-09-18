import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact_model.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper();
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
        party_id INTEGER,
        contact_name TEXT,
        type TEXT,
        currency TEXT DEFAULT 'ليرة سورية',
        date TEXT,
        created_at TEXT,
        subtotal REAL DEFAULT 0.0,
        discount REAL DEFAULT 0.0,
        total_amount REAL DEFAULT 0.0,
        net_total REAL DEFAULT 0.0,
        paid_amount REAL DEFAULT 0.0,
        remaining_amount REAL DEFAULT 0.0
      )
    ''');

    // 4. جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        product_id INTEGER,
        product_name TEXT,
        quantity REAL DEFAULT 0.0,
        unit_price REAL DEFAULT 0.0,
        price REAL DEFAULT 0.0,
        total REAL DEFAULT 0.0,
        FOREIGN KEY (invoice_id) REFERENCES sales_invoices (id) ON DELETE CASCADE
      )
    ''');

    // 5. جدول حركات الصندوق (جديد)
    await db.execute('''
      CREATE TABLE cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT NOT NULL,
        type TEXT NOT NULL, -- 'income' (مقبوضات) أو 'expense' (مدفوعات)
        amount REAL NOT NULL,
        notes TEXT,
        date TEXT NOT NULL
      )
    ''');
  }

  // --- عمليات حركات الصندوق (Cash Journal Operations) ---

  Future<void> addCashTransaction({
    required int? contactId,
    required String contactName,
    required String type, // 'income' أو 'expense'
    required double amount,
    required String notes,
    required String date,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. تسجيل حركة الصندوق
      await txn.insert('cash_transactions', {
        'contact_id': contactId,
        'contact_name': contactName,
        'type': type,
        'amount': amount,
        'notes': notes,
        'date': date,
      });

      // 2. تحديث رصيد الحساب المالي المربوط بالحركة
      if (contactId != null) {
        // المقبوضات تخفّض الدين على العميل (-)، والمدفوعات تزيد الدين (+)
        double balanceChange = (type == 'income') ? -amount : amount;
        await txn.rawUpdate(
          'UPDATE contacts SET balance_syr = balance_syr + ?, balance = balance + ? WHERE id = ?',
          [balanceChange, balanceChange, contactId],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await database;
    return await db.query(
      'cash_transactions',
      where: 'date LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'id DESC',
    );
  }

  // --- عمليات الأطراف والعملاء ---

  Future<List<ContactModel>> getContacts() async {
    final db = await database;
    final result = await db.query('contacts');
    return result.map((json) => ContactModel.fromMap(json)).toList();
  }

  Future<List<ContactModel>> searchContacts(String query) async {
    final db = await database;
    final result = await db.query(
      'contacts',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((json) => ContactModel.fromMap(json)).toList();
  }

  Future<int> insertContact(ContactModel contact) async {
    final db = await database;
    return await db.insert('contacts', contact.toMap());
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

  // --- عمليات حفظ الفواتير ---

  Future<void> saveInvoiceWithDetails(
    Map<String, dynamic> invoiceData,
    List<dynamic> items,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      int invoiceId = await txn.insert('sales_invoices', invoiceData);

      for (var item in items) {
        final Map<String, dynamic> itemMap = {
          'invoice_id': invoiceId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'price': item.price,
          'unit_price': item.price,
          'quantity': item.quantity,
          'total': item.total,
        };
        await txn.insert('invoice_items', itemMap);

        if (item.product.id != null) {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity - ?, stock_quantity = stock_quantity - ? WHERE id = ?',
            [item.quantity, item.quantity, item.product.id],
          );
        }
      }

      if (invoiceData['party_id'] != null) {
        double remaining = (invoiceData['remaining_amount'] as num?)?.toDouble() ?? 0.0;
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

  Future<void> insertInvoice(Map<String, dynamic> invoiceData, List items) async {
    await saveInvoiceWithDetails(invoiceData, items);
  }
}
