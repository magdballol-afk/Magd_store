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
      onUpgrade: (db, oldVersion, newVersion) async {
        // إدارة التحديثات في حال وجود جداول جديدة
      },
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
        type $textType,
        balance $realType DEFAULT 0.0
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

    // جدول حركة الصندوق (دفتر اليومية)
    await db.execute('''
      CREATE TABLE cash_transactions (
        id $idType,
        contact_id $integerType,
        amount $realType,
        type $textType,
        note $textNullable,
        date $textType
      )
    ''');
  }

  // ==================== المنتجات والتحركات ====================

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
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getProductMovements(int productId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT ii.*, i.date, i.type as invoice_type 
      FROM invoice_items ii
      JOIN invoices i ON ii.invoice_id = i.id
      WHERE ii.product_id = ?
      ORDER BY i.date DESC
    ''', [productId]);
  }

  // ==================== جهات الاتصال والرصيد ====================

  Future<int> insertContact(Map<String, dynamic> contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'name ASC');
  }

  Future<void> updateContactBalance(int? contactId, double adjustment) async {
    if (contactId == null || contactId <= 0) return;
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE contacts SET balance = COALESCE(balance, 0.0) + ? WHERE id = ?',
      [adjustment, contactId],
    );
  }

  // ==================== الصندوق / اليومية ====================

  Future<List<Map<String, dynamic>>> getDailyTransactions(String formattedDate) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT ct.*, c.name as contact_name 
      FROM cash_transactions ct
      LEFT JOIN contacts c ON ct.contact_id = c.id
      WHERE ct.date LIKE ?
      ORDER BY ct.id DESC
    ''', ['$formattedDate%']);
  }

  Future<int> addCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('cash_transactions', row);
  }

  Future<int> updateCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'cash_transactions',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteCashTransaction(int transactionId) async {
    final db = await instance.database;
    return await db.delete(
      'cash_transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // ==================== الفواتير ====================

  Future<int> addFullInvoice({
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
      // 1. إدراج الفاتورة
      invoiceId = await txn.insert('invoices', {
        'contact_id': contactId,
        'type': type,
        'total_amount': totalAmount,
        'discount': discount,
        'net_amount': netAmount,
        'paid_amount': paidAmount,
        'date': date ?? DateTime.now().toIso8601String(),
      });

      // 2. إدراج عناصر الفاتورة وتعديل كميات المنتجات
      for (var item in itemsList) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
          'total': item['total'],
        });

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

      // 3. تحديث رصيد العميل بناءً على المتبقي (غير المسدد)
      if (contactId > 0) {
        final double remaining = netAmount - paidAmount;
        if (remaining != 0) {
          double adjustment = 0.0;
          if (type == 'sale' || type == 'mefraq') {
            adjustment = remaining; // دين إضافي على العميل (+)
          } else if (type == 'buy' || type == 'purchase') {
            adjustment = -remaining; // مستحق إضافي للمورد (-)
          }

          await txn.rawUpdate(
            'UPDATE contacts SET balance = COALESCE(balance, 0.0) + ? WHERE id = ?',
            [adjustment, contactId],
          );
        }
      }
    });

    return invoiceId;
  }

  Future<int> updateFullInvoice({
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

    int result = 0;
    await db.transaction((txn) async {
      // 1. جلب الفاتورة القديمة لإلغاء تأثيرها المالي على العميل والمخزون
      final oldInvoiceResult = await txn.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      if (oldInvoiceResult.isNotEmpty) {
        final oldInv = oldInvoiceResult.first;
        final int oldContactId = (oldInv['contact_id'] as num).toInt();
        final String oldType = oldInv['type'].toString();
        final double oldNet = (oldInv['net_amount'] as num).toDouble();
        final double oldPaid = (oldInv['paid_amount'] as num).toDouble();
        final double oldRemaining = oldNet - oldPaid;

        // عكس تأثير الرصيد القديم
        if (oldContactId > 0 && oldRemaining != 0) {
          double reverseAdjustment = 0.0;
          if (oldType == 'sale' || oldType == 'mefraq') {
            reverseAdjustment = -oldRemaining;
          } else if (oldType == 'buy' || oldType == 'purchase') {
            reverseAdjustment = oldRemaining;
          }
          await txn.rawUpdate(
            'UPDATE contacts SET balance = COALESCE(balance, 0.0) + ? WHERE id = ?',
            [reverseAdjustment, oldContactId],
          );
        }

        // عكس الكميات القديمة في جدول المنتجات
        final oldItems = await txn.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
        for (var item in oldItems) {
          final double qty = (item['quantity'] as num).toDouble();
          final int prodId = (item['product_id'] as num).toInt();

          if (oldType == 'sale' || oldType == 'mefraq') {
            await txn.rawUpdate('UPDATE products SET quantity = quantity + ? WHERE id = ?', [qty, prodId]);
          } else if (oldType == 'buy' || oldType == 'purchase') {
            await txn.rawUpdate('UPDATE products SET quantity = quantity - ? WHERE id = ?', [qty, prodId]);
          }
        }
      }

      // 2. تحديث بيانات الفاتورة
      final Map<String, dynamic> row = {};
      if (contactId != null) row['contact_id'] = contactId;
      if (type != null) row['type'] = type;
      if (totalAmount != null) row['total_amount'] = totalAmount;
      if (discount != null) row['discount'] = discount;
      if (netAmount != null) row['net_amount'] = netAmount;
      if (paidAmount != null) row['paid_amount'] = paidAmount;

      if (row.isNotEmpty) {
        result = await txn.update(
          'invoices',
          row,
          where: 'id = ?',
          whereArgs: [invoiceId],
        );
      }

      // 3. إعادة إدراج عناصر الفاتورة الجدد وتطبيق الكميات الجديدة
      if (itemsList != null) {
        await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);

        final String currentType = type ?? (oldInvoiceResult.isNotEmpty ? oldInvoiceResult.first['type'].toString() : 'sale');

        for (var item in itemsList) {
          await txn.insert('invoice_items', {
            'invoice_id': invoiceId,
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'price': item['price'],
            'total': item['total'],
          });

          if (currentType == 'sale' || currentType == 'mefraq') {
            await txn.rawUpdate('UPDATE products SET quantity = quantity - ? WHERE id = ?', [item['quantity'], item['product_id']]);
          } else if (currentType == 'buy' || currentType == 'purchase') {
            await txn.rawUpdate('UPDATE products SET quantity = quantity + ? WHERE id = ?', [item['quantity'], item['product_id']]);
          }
        }
      }

      // 4. تطبيق تأثير الرصيد الجديد على العميل
      final int newContactId = contactId ?? (oldInvoiceResult.isNotEmpty ? (oldInvoiceResult.first['contact_id'] as num).toInt() : 0);
      final String newType = type ?? (oldInvoiceResult.isNotEmpty ? oldInvoiceResult.first['type'].toString() : 'sale');
      final double newNet = netAmount ?? (oldInvoiceResult.isNotEmpty ? (oldInvoiceResult.first['net_amount'] as num).toDouble() : 0.0);
      final double newPaid = paidAmount ?? (oldInvoiceResult.isNotEmpty ? (oldInvoiceResult.first['paid_amount'] as num).toDouble() : 0.0);
      final double newRemaining = newNet - newPaid;

      if (newContactId > 0 && newRemaining != 0) {
        double newAdjustment = 0.0;
        if (newType == 'sale' || newType == 'mefraq') {
          newAdjustment = newRemaining;
        } else if (newType == 'buy' || newType == 'purchase') {
          newAdjustment = -newRemaining;
        }
        await txn.rawUpdate(
          'UPDATE contacts SET balance = COALESCE(balance, 0.0) + ? WHERE id = ?',
          [newAdjustment, newContactId],
        );
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

  // ==================== إغلاق السنة المالية ====================

  Future<void> executeFiscalYearRollover(int newYear) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // إزالة حركات السنة القديمة مع الإبقاء على الأرصدة والمنتجات
      await txn.delete('cash_transactions');
      await txn.delete('invoice_items');
      await txn.delete('invoices');
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
