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
      version: 3, // رقم الإصدار الحسابي
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const realDefaultZero = 'REAL NOT NULL DEFAULT 0.0';
    const integerType = 'INTEGER NOT NULL';

    // جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        barcode $textNullable,
        buy_price $realDefaultZero,
        retail_price $realDefaultZero,
        half_wholesale_price $realDefaultZero,
        wholesale_price $realDefaultZero,
        quantity $realDefaultZero
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

  // ==================== المنتجات والتحركات والباركود ====================

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    final Map<String, dynamic> data = Map.from(product);

    // حماية ضد NOT NULL constraints للشاشات التي لا تحتوي حقول الجملة
    data['half_wholesale_price'] ??= 0.0;
    data['wholesale_price'] ??= 0.0;
    data['buy_price'] ??= 0.0;
    data['retail_price'] ??= 0.0;
    data['quantity'] ??= 0.0;

    return await db.insert('products', data);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  /// جلب منتج بواسطة الباركود
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    final Map<String, dynamic> data = Map.from(product);

    // حماية ضد NOT NULL constraints أثناء التحديث
    data['half_wholesale_price'] ??= 0.0;
    data['wholesale_price'] ??= 0.0;
    data['buy_price'] ??= 0.0;
    data['retail_price'] ??= 0.0;
    data['quantity'] ??= 0.0;

    return await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
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

  // ==================== الصندوق / اليومية المربوط بالفواتير ====================

  /// 1. جلب إجمالي المقبوضات الشامل لليوم (مبيعات + سندات قبض)
  Future<double> getDailyReceipts(String formattedDate) async {
    final db = await instance.database;

    // أ. المبالغ المقبوضة نقداً في فواتير المبيعات والمفرق
    final salesResult = await db.rawQuery('''
      SELECT SUM(paid_amount) as total 
      FROM invoices 
      WHERE (type = 'sale' OR type = 'mefraq') AND date LIKE ?
    ''', ['$formattedDate%']);

    double salesPaid = (salesResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // ب. المقبوضات اليدوية من حركة الصندوق (سندات القبض)
    final cashResult = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM cash_transactions 
      WHERE (type = 'income' OR type = 'قبض') AND date LIKE ?
    ''', ['$formattedDate%']);

    double cashIncome = (cashResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return salesPaid + cashIncome;
  }

  /// 2. جلب إجمالي المدفوعات الشامل لليوم (مشتريات + سندات دفع/مصاريف)
  Future<double> getDailyPayments(String formattedDate) async {
    final db = await instance.database;

    // أ. المبالغ المدفوعة نقداً في فواتير المشتريات
    final purchaseResult = await db.rawQuery('''
      SELECT SUM(paid_amount) as total 
      FROM invoices 
      WHERE (type = 'buy' OR type = 'purchase') AND date LIKE ?
    ''', ['$formattedDate%']);

    double purchasePaid = (purchaseResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // ب. المدفوعات اليدوية من حركة الصندوق (سندات الصرف/الدفع)
    final cashResult = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM cash_transactions 
      WHERE (type = 'expense' OR type = 'دفع') AND date LIKE ?
    ''', ['$formattedDate%']);

    double cashExpense = (cashResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return purchasePaid + cashExpense;
  }

  /// 3. جلب كافة حركات اليوم الشاملة (فواتير + سندات) للعرض في الجدول السفلي
  Future<List<Map<String, dynamic>>> getAllDailyTransactions(String formattedDate) async {
    final db = await instance.database;

    // أ. حركات الصندوق اليدوية
    final cashTx = await db.rawQuery('''
      SELECT ct.id, 
             COALESCE(c.name, 'غير محدد') as contact_name, 
             ct.amount, 
             ct.type, 
             COALESCE(ct.note, 'سند صندوق') as note, 
             ct.date
      FROM cash_transactions ct
      LEFT JOIN contacts c ON ct.contact_id = c.id
      WHERE ct.date LIKE ?
    ''', ['$formattedDate%']);

    // ب. المقبوضات النقدية من فواتير المبيعات
    final salesInvoices = await db.rawQuery('''
      SELECT i.id, 
             COALESCE(c.name, 'عميل عام') as contact_name, 
             i.paid_amount as amount, 
             'قبض' as type, 
             ('دفعة فاتورة مبيعات #' || i.id) as note, 
             i.date
      FROM invoices i
      LEFT JOIN contacts c ON i.contact_id = c.id
      WHERE (i.type = 'sale' OR i.type = 'mefraq') 
        AND i.paid_amount > 0 
        AND i.date LIKE ?
    ''', ['$formattedDate%']);

    // ج. المدفوعات النقدية من فواتير المشتريات
    final purchaseInvoices = await db.rawQuery('''
      SELECT i.id, 
             COALESCE(c.name, 'مورد عام') as contact_name, 
             i.paid_amount as amount, 
             'دفع' as type, 
             ('دفعة فاتورة مشتريات #' || i.id) as note, 
             i.date
      FROM invoices i
      LEFT JOIN contacts c ON i.contact_id = c.id
      WHERE (i.type = 'buy' OR i.type = 'purchase') 
        AND i.paid_amount > 0 
        AND i.date LIKE ?
    ''', ['$formattedDate%']);

    List<Map<String, dynamic>> allList = [];
    allList.addAll(cashTx);
    allList.addAll(salesInvoices);
    allList.addAll(purchaseInvoices);

    return allList;
  }

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
