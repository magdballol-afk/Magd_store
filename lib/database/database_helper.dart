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
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        buy_price $realType,
        retail_price $realType,
        half_wholesale_price $realType,
        wholesale_price $realType,
        quantity $realType
      )
    ''');

    // جدول جهات الاتصال (العملاء والموردين)
    await db.execute('''
      CREATE TABLE contacts (
        id $idType,
        name $textType,
        phone $textNullable,
        type $textType
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id $idType,
        contact_id $integerType,
        type $textType,
        total_amount $realType,
        discount $realType,
        net_amount $realType,
        paid_amount $realType,
        date $textType
      )
    ''');

    // جدول عناصر الفاتورة
    await db.execute('''
      CREATE TABLE invoice_items (
        id $idType,
        invoice_id $integerType,
        product_id $integerType,
        quantity $realType,
        price $realType,
        total $realType
      )
    ''');
  }

  // ==================== عمليات المنتجات ====================

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
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== عمليات جهات الاتصال ====================

  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'name ASC');
  }

  // ==================== عمليات الفواتير ====================

  Future<int> insertInvoice({
    required int contactId,
    required String type,
    required double totalAmount,
    required double discount,
    required double netAmount,
    required double paidAmount,
    required List<Map<String, dynamic>> itemsList,
    String? date,
  }) async {
    final db = await instance.database;
    int invoiceId = 0;

    await db.transaction((txn) async {
      invoiceId = await txn.insert('invoices', {
        'contact_id': contactId,
        'type': type,
        'total_amount': totalAmount,
        'discount': discount,
        'net_amount': netAmount,
        'paid_amount': paidAmount,
        'date': date ?? DateTime.now().toIso8601String(),
      });

      for (var item in itemsList) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
          'total': item['total'],
        });

        // تحديث كميات المخزون
        if (type == 'sale' || type == 'mefraq') {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity - ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        } else if (type == 'buy' || type == 'purchase') {
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        }
      }
    });

    return invoiceId;
  }

  Future<int> updateInvoice({
    required int invoiceId,
    int? contactId,
    String? type,
    double? totalAmount,
    double? discount,
    double? netAmount,
    double? paidAmount,
    List<Map<String, dynamic>>? itemsList,
  }) async {
    final db = await instance.database;

    final Map<String, dynamic> row = {};
    if (contactId != null) row['contact_id'] = contactId;
    if (type != null) row['type'] = type;
    if (totalAmount != null) row['total_amount'] = totalAmount;
    if (discount != null) row['discount'] = discount;
    if (netAmount != null) row['net_amount'] = netAmount;
    if (paidAmount != null) row['paid_amount'] = paidAmount;

    int result = 0;
    await db.transaction((txn) async {
      if (row.isNotEmpty) {
        result = await txn.update(
          'invoices',
          row,
          where: 'id = ?',
          whereArgs: [invoiceId],
        );
      }

      if (itemsList != null) {
        await txn.delete(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [invoiceId],
        );

        for (var item in itemsList) {
          await txn.insert('invoice_items', {
            'invoice_id': invoiceId,
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'price': item['price'],
            'total': item['total'],
          });
        }
      }
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getInvoiceItems(int invoiceId) async {
    final db = await instance.database;
    return await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    await db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
