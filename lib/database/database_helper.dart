import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product.dart';

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
      version: 3, // تم الترفيع للإصدار 3 لدعم هيكل أسعار المنتجات الموحد
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. جدول العملاء / الحسابات
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 2. جدول المنتجات المتوافق كلياً مع بطاقة المادة وإضافة المادة
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        buy_price REAL NOT NULL DEFAULT 0.0,
        wholesale_price REAL NOT NULL DEFAULT 0.0,
        retail_price REAL NOT NULL DEFAULT 0.0,
        stock_quantity REAL NOT NULL DEFAULT 0.0,
        price REAL DEFAULT 0.0,
        quantity REAL DEFAULT 0.0
      )
    ''');

    // 3. جدول حركات الصندوق اليومية
    await db.execute('''
      CREATE TABLE cash_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE SET NULL
      )
    ''');

    // 4. جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id INTEGER,
        contact_name TEXT,
        type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL DEFAULT 0.0,
        total_amount REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        remaining_amount REAL NOT NULL DEFAULT 0.0,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE SET NULL
      )
    ''');

    // 5. جدول تفاصيل عناصر الفاتورة
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

  // معالجة التحديث الهيكلي لقواعد البيانات القائمة دون مسح البيانات
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN total REAL DEFAULT 0.0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN remaining_amount REAL DEFAULT 0.0');
      } catch (_) {}
    }

    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE products ADD COLUMN buy_price REAL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute('ALTER TABLE products ADD COLUMN wholesale_price REAL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute('ALTER TABLE products ADD COLUMN retail_price REAL DEFAULT 0.0'); } catch (_) {}
      try { await db.execute('ALTER TABLE products ADD COLUMN stock_quantity REAL DEFAULT 0.0'); } catch (_) {}
    }
  }

  // ==========================================
  //  قسم تدوير السنة المالية
  // ==========================================

  Future<void> executeFiscalYearRollover(String newYear) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final incomeResult = await txn.rawQuery(
        "SELECT SUM(amount) as total FROM cash_transactions WHERE type = 'income'",
      );
      final expenseResult = await txn.rawQuery(
        "SELECT SUM(amount) as total FROM cash_transactions WHERE type = 'expense'",
      );

      final double totalIncome = double.tryParse((incomeResult.first['total'] ?? 0.0).toString()) ?? 0.0;
      final double totalExpense = double.tryParse((expenseResult.first['total'] ?? 0.0).toString()) ?? 0.0;
      final double netCashBalance = totalIncome - totalExpense;

      await txn.delete('invoice_items');
      await txn.delete('invoices');
      await txn.delete('cash_transactions');

      if (netCashBalance != 0) {
        final String todayDate = DateTime.now().toIso8601String().split('T').first;
        final String type = netCashBalance > 0 ? 'income' : 'expense';

        await txn.insert('cash_transactions', {
          'contact_id': null,
          'contact_name': 'رصيد افتتاحي',
          'type': type,
          'amount': netCashBalance.abs(),
          'notes': 'رصيد افتتاحي من تدوير السنة المالية $newYear',
          'date': todayDate,
        });
      }
    });
  }

  // ==========================================
  //  قسم إدارة العملاء (Contacts)
  // ==========================================

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'name ASC');
  }

  Future<int> insertContact(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('contacts', row);
  }

  Future<int> updateContactBalance(int? contactId, double adjustmentAmount) async {
    if (contactId == null) return 0;
    final db = await instance.database;
    return await db.rawUpdate('''
      UPDATE contacts 
      SET balance = balance + ? 
      WHERE id = ?
    ''', [adjustmentAmount, contactId]);
  }

  // ==========================================
  //  قسم إدارة المنتجات (Products)
  // ==========================================

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  // دالة تحديث المنتج المتوافقة مع كائن Product ودعم التحديث المباشر
  Future<int> updateProduct(dynamic productOrId, [Map<String, dynamic>? rowData]) async {
    final db = await instance.database;

    if (productOrId is Product) {
      return await db.update(
        'products',
        productOrId.toMap(),
        where: 'id = ?',
        whereArgs: [productOrId.id],
      );
    } else if (productOrId is int && rowData != null) {
      return await db.update(
        'products',
        rowData,
        where: 'id = ?',
        whereArgs: [productOrId],
      );
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getProductMovements(dynamic productId) async {
    if (productId == null) return [];
    final db = await instance.database;
    final id = productId is int ? productId : int.tryParse(productId.toString());
    if (id == null) return [];

    return await db.rawQuery('''
      SELECT 
        i.date,
        i.type,
        i.contact_name,
        ii.quantity,
        ii.unit_price,
        ii.total
      FROM invoice_items ii
      INNER JOIN invoices i ON ii.invoice_id = i.id
      WHERE ii.product_id = ?
      ORDER BY i.date DESC, i.id DESC
    ''', [id]);
  }

  // ==========================================
  //  قسم حركة الصندوق (Cash Transactions)
  // ==========================================

  Future<List<Map<String, dynamic>>> getDailyTransactions(String date) async {
    final db = await instance.database;
    return await db.query(
      'cash_transactions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
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

  Future<int> deleteCashTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cash_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  //  قسم حفظ الفواتير وتحديث الحسابات والصندوق
  // ==========================================

  Future<void> addFullInvoice({
    required int? contactId,
    required String contactName,
    required String type,
    required double subtotal,
    required double discount,
    required double totalAmount,
    required double paidAmount,
    required List<Map<String, dynamic>> items,
    required String date,
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final double remaining = totalAmount - paidAmount;

      final invoiceId = await txn.insert('invoices', {
        'contact_id': contactId,
        'contact_name': contactName,
        'type': type,
        'subtotal': subtotal,
        'discount': discount,
        'total': totalAmount,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'remaining_amount': remaining,
        'date': date,
      });

      for (var item in items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'unit_price': item['unit_price'],
          'quantity': item['quantity'],
          'discount': item['discount'] ?? 0.0,
          'total': item['total'],
        });

        double qtyChange = (item['quantity'] as num).toDouble();
        if (type == 'sale') {
          qtyChange = -qtyChange;
        }

        await txn.rawUpdate('''
          UPDATE products 
          SET stock_quantity = stock_quantity + ?,
              quantity = quantity + ? 
          WHERE id = ?
        ''', [qtyChange, qtyChange, item['product_id']]);
      }

      if (contactId != null && remaining != 0) {
        double balanceAdjustment = (type == 'sale') ? remaining : -remaining;
        await txn.rawUpdate('''
          UPDATE contacts 
          SET balance = balance + ? 
          WHERE id = ?
        ''', [balanceAdjustment, contactId]);
      }

      if (paidAmount > 0) {
        String cashType = (type == 'sale') ? 'income' : 'expense';
        String notes = (type == 'sale')
            ? 'دفعة نقداً عن فاتورة مبيعات رقم #$invoiceId'
            : 'دفعة نقداً عن فاتورة مشتريات رقم #$invoiceId';

        await txn.insert('cash_transactions', {
          'contact_id': contactId,
          'contact_name': contactName,
          'type': cashType,
          'amount': paidAmount,
          'notes': notes,
          'date': date,
        });
      }
    });
  }

  // ==========================================
  //  دالة تعديل الفاتورة بالكامل وتحديث الأرصدة والكميات
  // ==========================================

  Future<void> updateFullInvoice({
    required int invoiceId,
    required int? contactId,
    required String contactName,
    required String type,
    required double subtotal,
    required double discount,
    required double totalAmount,
    required double paidAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      final oldInvoiceList = await txn.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      if (oldInvoiceList.isEmpty) return;

      final oldInvoice = oldInvoiceList.first;
      final String oldType = (oldInvoice['type'] ?? 'sale').toString();
      final int? oldContactId = oldInvoice['contact_id'] as int?;
      final double oldTotal = double.tryParse((oldInvoice['total_amount'] ?? oldInvoice['total'] ?? 0.0).toString()) ?? 0.0;
      final double oldPaid = double.tryParse((oldInvoice['paid_amount'] ?? 0.0).toString()) ?? 0.0;
      final double oldRemaining = oldTotal - oldPaid;

      if (oldContactId != null && oldRemaining != 0) {
        double reverseAdjustment = (oldType == 'sale') ? -oldRemaining : oldRemaining;
        await txn.rawUpdate('''
          UPDATE contacts 
          SET balance = balance + ? 
          WHERE id = ?
        ''', [reverseAdjustment, oldContactId]);
      }

      final oldItems = await txn.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (var item in oldItems) {
        final int? prodId = item['product_id'] as int?;
        final double qty = double.tryParse((item['quantity'] ?? 0.0).toString()) ?? 0.0;
        if (prodId != null) {
          double reverseQty = (oldType == 'sale') ? qty : -qty;
          await txn.rawUpdate('''
            UPDATE products 
            SET stock_quantity = stock_quantity + ?,
                quantity = quantity + ? 
            WHERE id = ?
          ''', [reverseQty, reverseQty, prodId]);
        }
      }

      final double remaining = totalAmount - paidAmount;
      await txn.update(
        'invoices',
        {
          'contact_id': contactId,
          'contact_name': contactName,
          'type': type,
          'subtotal': subtotal,
          'discount': discount,
          'total': totalAmount,
          'total_amount': totalAmount,
          'paid_amount': paidAmount,
          'remaining_amount': remaining,
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);

      for (var item in items) {
        final int? prodId = item['product_id'] as int?;
        final double qty = double.tryParse((item['quantity'] ?? 0.0).toString()) ?? 0.0;

        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': prodId,
          'product_name': item['product_name'] ?? 'مادة',
          'unit_price': item['unit_price'],
          'quantity': qty,
          'discount': item['discount'] ?? 0.0,
          'total': item['total'],
        });

        if (prodId != null) {
          double newQtyChange = (type == 'sale') ? -qty : qty;
          await txn.rawUpdate('''
            UPDATE products 
            SET stock_quantity = stock_quantity + ?,
                quantity = quantity + ? 
            WHERE id = ?
          ''', [newQtyChange, newQtyChange, prodId]);
        }
      }

      if (contactId != null && remaining != 0) {
        double newBalanceAdjustment = (type == 'sale') ? remaining : -remaining;
        await txn.rawUpdate('''
          UPDATE contacts 
          SET balance = balance + ? 
          WHERE id = ?
        ''', [newBalanceAdjustment, contactId]);
      }
    });
  }
}
