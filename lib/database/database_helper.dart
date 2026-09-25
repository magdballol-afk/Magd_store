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

  // ==========================================
  // 1. إنشاء الجداول الكاملة للنظام
  // ==========================================
  Future _createDB(Database db, int version) async {
    // جدول المنتجات والأسعار
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

    // جدول العملاء والموردين
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT,
        balance REAL DEFAULT 0.0
      )
    ''');

    // جدول الفواتير الرئيسي
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

    // جدول عناصر الفاتورة
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

    // جدول حركة الصندوق
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

  // ترقية قاعدة البيانات التلقائية
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN half_wholesale_price REAL DEFAULT 0.0');
    }
  }

  // ==========================================
  // 2. عمليات المنتجات وحركاتها (Products)
  // ==========================================
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<int> updateProduct(dynamic idOrProduct, [Map<String, dynamic>? data]) async {
    final db = await instance.database;
    if (idOrProduct is Map<String, dynamic>) {
      return await db.update('products', idOrProduct, where: 'id = ?', whereArgs: [idOrProduct['id']]);
    } else if (data != null) {
      return await db.update('products', data, where: 'id = ?', whereArgs: [idOrProduct]);
    }
    return 0;
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

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
  // 3. عمليات الحسابات والعملاء (Contacts)
  // ==========================================
  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'id DESC');
  }

  Future<int> updateContactBalance([dynamic arg1, dynamic arg2]) async {
    final db = await instance.database;
    int? contactId;
    double amt = 0.0;

    if (arg1 is int) contactId = arg1;
    if (arg2 is num) amt = arg2.toDouble();

    if (contactId == null) return 0;

    return await db.rawUpdate(
      'UPDATE contacts SET balance = balance + ? WHERE id = ?',
      [amt, contactId],
    );
  }

  // ==========================================
  // 4. عمليات حركة الصندوق (Cash Journal)
  // ==========================================
  Future<List<Map<String, dynamic>>> getDailyTransactions([String? date]) async {
    final db = await instance.database;
    final String queryDate = date ?? DateTime.now().toIso8601String().substring(0, 10);
    return await db.query('cash_journal', where: 'date LIKE ?', whereArgs: ['$queryDate%'], orderBy: 'id DESC');
  }

  Future<int> addCashTransaction([Map<String, dynamic>? row]) async {
    if (row == null) return 0;
    final db = await instance.database;
    return await db.insert('cash_journal', row);
  }

  Future<int> updateCashTransaction([Map<String, dynamic>? row]) async {
    if (row == null) return 0;
    final db = await instance.database;
    return await db.update('cash_journal', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteCashTransaction([dynamic transactionId]) async {
    if (transactionId == null) return 0;
    final db = await instance.database;
    return await db.delete('cash_journal', where: 'id = ?', whereArgs: [transactionId]);
  }

  // ==========================================
  // 5. عمليات الفواتير (Invoices) - تتيح المعاملات الموقعية والمسماة
  // ==========================================
  Future<int> addFullInvoice([
    Map<String, dynamic>? invoice,
    List<Map<String, dynamic>>? items,
  ], {
    dynamic invoiceId,
    dynamic contactId,
    dynamic type,
    dynamic totalAmount,
    dynamic discount,
    dynamic netAmount,
    dynamic paidAmount,
    dynamic remainingAmount,
    dynamic date,
    dynamic itemsList,
  }) async {
    final db = await instance.database;
    int newInvoiceId = 0;

    final Map<String, dynamic> invoiceData = invoice ?? {
      if (contactId != null) 'contact_id': contactId,
      if (type != null) 'type': type,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (discount != null) 'discount': discount,
      if (netAmount != null) 'net_amount': netAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (remainingAmount != null) 'remaining_amount': remainingAmount,
      if (date != null) 'date': date,
    };

    final List<Map<String, dynamic>> itemList = items ?? (itemsList as List<Map<String, dynamic>>? ?? []);

    await db.transaction((txn) async {
      newInvoiceId = await txn.insert('invoices', invoiceData);
      for (var item in itemList) {
        item['invoice_id'] = newInvoiceId;
        await txn.insert('invoice_items', item);
      }
    });

    return newInvoiceId;
  }

  Future<void> updateFullInvoice([
    Map<String, dynamic>? invoice,
    List<Map<String, dynamic>>? items,
  ], {
    dynamic invoiceId,
    dynamic contactId,
    dynamic type,
    dynamic totalAmount,
    dynamic discount,
    dynamic netAmount,
    dynamic paidAmount,
    dynamic remainingAmount,
    dynamic date,
    dynamic itemsList,
  }) async {
    final db = await instance.database;

    final int targetId = invoice?['id'] ?? (invoiceId is int ? invoiceId : int.tryParse(invoiceId.toString()) ?? 0);
    final Map<String, dynamic> invoiceData = invoice ?? {
      'id': targetId,
      if (contactId != null) 'contact_id': contactId,
      if (type != null) 'type': type,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (discount != null) 'discount': discount,
      if (netAmount != null) 'net_amount': netAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (remainingAmount != null) 'remaining_amount': remainingAmount,
      if (date != null) 'date': date,
    };

    final List<Map<String, dynamic>> itemList = items ?? (itemsList as List<Map<String, dynamic>>? ?? []);

    await db.transaction((txn) async {
      await txn.update('invoices', invoiceData, where: 'id = ?', whereArgs: [targetId]);
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [targetId]);
      for (var item in itemList) {
        item['invoice_id'] = targetId;
        await txn.insert('invoice_items', item);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  // التدوير وإغلاق السنة المالية
  Future<bool> executeFiscalYearRollover([dynamic newYear]) async {
    final db = await instance.database;
    try {
      await db.transaction((txn) async {
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
