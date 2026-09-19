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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL DEFAULT 0
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
        total_amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id)
      )
    ''');
  }

  // ==========================================
  // 1. المنتجات (Products)
  // ==========================================

  // يدعم التمرير إما كـ Map كمُعامل أول أو كـ Named Arguments
  Future<int> insertProduct([
    Map<String, dynamic>? productData, {
    String? name,
    double? price,
    dynamic quantity,
  }) async {
    final db = await instance.database;
    if (productData != null) {
      return await db.insert('products', productData);
    }

    final double qty = (quantity is num)
        ? quantity.toDouble()
        : (double.tryParse(quantity?.toString() ?? '') ?? 0.0);

    return await db.insert('products', {
      'name': name ?? '',
      'price': price ?? 0.0,
      'quantity': qty,
    });
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  // ==========================================
  // 2. جهات الاتصال (Contacts)
  // ==========================================

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts');
  }

  Future<int> updateContactBalance(dynamic contactId, double adjustment) async {
    if (contactId == null) return 0;
    final int? id = (contactId is int) ? contactId : int.tryParse(contactId.toString());
    if (id == null) return 0;

    final db = await instance.database;
    return await db.rawUpdate(
      'UPDATE contacts SET balance = balance + ? WHERE id = ?',
      [adjustment, id],
    );
  }

  // ==========================================
  // 3. حركات الصندوق (Cash Transactions)
  // ==========================================

  Future<int> addCashTransaction([
    Map<String, dynamic>? transactionData, {
    int? contactId,
    String? contactName,
    String? type,
    double? amount,
    String? notes,
    String? date,
  }) async {
    final db = await instance.database;
    if (transactionData != null) {
      return await db.insert('cash_transactions', transactionData);
    }

    return await db.insert('cash_transactions', {
      'contact_id': contactId,
      'contact_name': contactName ?? '',
      'type': type ?? '',
      'amount': amount ?? 0.0,
      'notes': notes,
      'date': date ?? DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query(
      'cash_transactions',
      where: 'date LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateCashTransaction([
    Map<String, dynamic>? transactionData, {
    int? id,
    int? contactId,
    String? contactName,
    String? type,
    double? amount,
    String? notes,
  }) async {
    final db = await instance.database;
    if (transactionData != null) {
      final txId = transactionData['id'];
      return await db.update(
        'cash_transactions',
        transactionData,
        where: 'id = ?',
        whereArgs: [txId],
      );
    }

    return await db.update(
      'cash_transactions',
      {
        'contact_id': contactId,
        'contact_name': contactName,
        'type': type,
        'amount': amount,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCashTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cash_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // 4. الفواتير (Invoices)
  // ==========================================

  Future<int> addInvoice([
    Map<String, dynamic>? invoiceData, {
    int? contactId,
    String? contactName,
    double? totalAmount,
    String? date,
  }) async {
    final db = await instance.database;
    if (invoiceData != null) {
      return await db.insert('invoices', invoiceData);
    }

    return await db.insert('invoices', {
      'contact_id': contactId,
      'contact_name': contactName ?? '',
      'total_amount': totalAmount ?? 0.0,
      'date': date ?? DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
