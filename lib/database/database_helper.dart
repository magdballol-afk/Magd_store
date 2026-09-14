import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "store_accounting.db";
  static const _databaseVersion = 1;

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  // تفعيل دعم Foreign Keys في SQLite
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // إنشاء الجداول
  Future _onCreate(Database db, int version) async {
    // 1. جدول المواد/المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        category TEXT,
        quantity REAL DEFAULT 0.0,
        price_retail REAL DEFAULT 0.0,
        price_half_wholesale REAL DEFAULT 0.0,
        price_wholesale REAL DEFAULT 0.0
      )
    ''');

    // 2. جدول العملاء والموردين
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        type TEXT NOT NULL, -- 'عميل' أو 'مورد'
        balance_syp REAL DEFAULT 0.0,
        balance_usd REAL DEFAULT 0.0
      )
    ''');

    // 3. جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        invoice_type TEXT NOT NULL, -- 'مبيعات' أو 'مشتريات'
        contact_id INTEGER,
        contact_name TEXT,
        deal_type TEXT NOT NULL, -- 'مفرق', 'نصف جملة', 'جملة'
        payment_type TEXT NOT NULL, -- 'نقدي' أو 'آجل (دين)'
        currency TEXT NOT NULL, -- 'ليرة سورية' أو 'دولار (\$)'
        subtotal REAL NOT NULL,
        net_total REAL NOT NULL,
        previous_balance REAL DEFAULT 0.0,
        paid_amount REAL DEFAULT 0.0,
        remaining_balance REAL DEFAULT 0.0,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE SET NULL
      )
    ''');

    // 4. جدول مواد الفاتورة (تفاصيل)
    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');

    // 5. جدول حركات الصندوق
    await db.execute('''
      CREATE TABLE fund_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL, -- 'مقبوضات' أو 'مدفوعات'
        contact_id INTEGER,
        contact_name TEXT,
        amount REAL NOT NULL,
        currency TEXT NOT NULL, -- 'ليرة سورية' أو 'دولار (\$)'
        notes TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE SET NULL
      )
    ''');
  }

  // =========================================================
  //                     عمليات المواد (Products)
  // =========================================================

  Future<int> insertProduct(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    Database db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<int> updateProduct(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update('products', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProduct(int id) async {
    Database db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // =========================================================
  //                 عمليات العملاء والموردين (Contacts)
  // =========================================================

  Future<int> insertContact(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('contacts', row);
  }

  Future<List<Map<String, dynamic>>> getContactsByType(String type) async {
    Database db = await instance.database;
    return await db.query('contacts', where: 'type = ?', whereArgs: [type], orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getAllContacts() async {
    Database db = await instance.database;
    return await db.query('contacts', orderBy: 'name ASC');
  }

  // =========================================================
  //                     عمليات الفواتير (Invoices)
  // =========================================================

  /// حفظ فاتورة جديدة مع تفاصيلها وتحديث المخزون ورصيد العميل تلقائياً
  Future<int> insertFullInvoice(Map<String, dynamic> invoiceData, List<Map<String, dynamic>> items) async {
    Database db = await instance.database;

    return await db.transaction((txn) async {
      // 1. إدراج رأس الفاتورة
      int invoiceId = await txn.insert('invoices', invoiceData);

      // 2. إدراج مواد الفاتورة وتعديل كميات المخزون
      for (var item in items) {
        item['invoice_id'] = invoiceId;
        await txn.insert('invoice_items', item);

        // إن كان المادة مرتبطة برقم id منتج، نحدّث الكمية في المستودع
        if (item['product_id'] != null) {
          bool isSales = invoiceData['invoice_type'] == 'مبيعات';
          double qty = (item['quantity'] as num).toDouble();
          
          if (isSales) {
            await txn.rawUpdate(
              'UPDATE products SET quantity = quantity - ? WHERE id = ?',
              [qty, item['product_id']],
            );
          } else {
            await txn.rawUpdate(
              'UPDATE products SET quantity = quantity + ? WHERE id = ?',
              [qty, item['product_id']],
            );
          }
        }
      }

      // 3. تحديث رصيد العميل/المورد إن كانت الفاتورة آجلة أو فيها متبقي
      if (invoiceData['contact_id'] != null) {
        double remaining = (invoiceData['remaining_balance'] as num).toDouble();
        String currency = invoiceData['currency'];
        String column = currency == 'ليرة سورية' ? 'balance_syp' : 'balance_usd';

        await txn.rawUpdate(
          'UPDATE contacts SET $column = ? WHERE id = ?',
          [remaining, invoiceData['contact_id']],
        );
      }

      return invoiceId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    Database db = await instance.database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getInvoiceItems(int invoiceId) async {
    Database db = await instance.database;
    return await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  // =========================================================
  //               عمليات حركة الصندوق (Fund Transactions)
  // =========================================================

  Future<int> insertFundTransaction(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.transaction((txn) async {
      int id = await txn.insert('fund_transactions', row);

      // تحديث رصيد الحساب المالي إن وجد
      if (row['contact_id'] != null) {
        double amount = (row['amount'] as num).toDouble();
        String type = row['type']; // مقبوضات أو مدفوعات
        String currency = row['currency'];
        String column = currency == 'ليرة سورية' ? 'balance_syp' : 'balance_usd';

        // المقبوضات تنقص الدين على العميل، والمدفوعات تنقص الدين للمورد
        double change = type == 'مقبوضات' ? -amount : amount;

        await txn.rawUpdate(
          'UPDATE contacts SET $column = $column + ? WHERE id = ?',
          [change, row['contact_id']],
        );
      }
      return id;
    });
  }

  Future<List<Map<String, dynamic>>> getFundTransactionsByDate(String date) async {
    Database db = await instance.database;
    return await db.query('fund_transactions', where: 'date = ?', whereArgs: [date], orderBy: 'id DESC');
  }
}
