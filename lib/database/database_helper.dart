import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

    // 2. جدول المنتجات
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0.0,
        quantity REAL NOT NULL DEFAULT 0.0
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

    // 4. جدول الفواتير (يحتوي على total و total_amount و remaining_amount لمنع أي تعارض)
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

  // معالجة التحديث الهيكلي لقواعد البيانات القائمة
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN total REAL DEFAULT 0.0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN remaining_amount REAL DEFAULT 0.0');
      } catch (_) {}
    }
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

  Future<int> updateProduct(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'products',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
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

      // 1. إدراج رأس الفاتورة مع تدعيم total و total_amount و remaining_amount
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

      // 2. إدراج عناصر الفاتورة وتحديث كميات المواد بالمخزن
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
          SET quantity = quantity + ? 
          WHERE id = ?
        ''', [qtyChange, item['product_id']]);
      }

      // 3. تعديل رصيد العميل حسب المتبقي غير المسدد
      if (contactId != null && remaining != 0) {
        double balanceAdjustment = (type == 'sale') ? remaining : -remaining;
        await txn.rawUpdate('''
          UPDATE contacts 
          SET balance = balance + ? 
          WHERE id = ?
        ''', [balanceAdjustment, contactId]);
      }

      // 4. تسجيل الدفعة المسددة نقداً في حركة الصندوق
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
      // 1. جلب بيانات الفاتورة القديمة للربط وإلغاء تأثيرها
      final oldInvoiceList = await txn.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
      if (oldInvoiceList.isEmpty) return;

      final oldInvoice = oldInvoiceList.first;
      final String oldType = (oldInvoice['type'] ?? 'sale').toString();
      final int? oldContactId = oldInvoice['contact_id'] as int?;
      final double oldTotal = double.tryParse((oldInvoice['total_amount'] ?? oldInvoice['total'] ?? 0.0).toString()) ?? 0.0;
      final double oldPaid = double.tryParse((oldInvoice['paid_amount'] ?? 0.0).toString()) ?? 0.0;
      final double oldRemaining = oldTotal - oldPaid;

      // إلغاء تأثير رصيد العميل القديم
      if (oldContactId != null && oldRemaining != 0) {
        double reverseAdjustment = (oldType == 'sale') ? -oldRemaining : oldRemaining;
        await txn.rawUpdate('''
          UPDATE contacts 
          SET balance = balance + ? 
          WHERE id = ?
        ''', [reverseAdjustment, oldContactId]);
      }

      // إلغاء كميات عناصر الفاتورة القديمة من المخزن
      final oldItems = await txn.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (var item in oldItems) {
        final int? prodId = item['product_id'] as int?;
        final double qty = double.tryParse((item['quantity'] ?? 0.0).toString()) ?? 0.0;
        if (prodId != null) {
          double reverseQty = (oldType == 'sale') ? qty : -qty;
          await txn.rawUpdate('''
            UPDATE products 
            SET quantity = quantity + ? 
            WHERE id = ?
          ''', [reverseQty, prodId]);
        }
      }

      // 2. تحديث بيانات الفاتورة الرئيسية بنفس الـ ID
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

      // 3. مسح بنود الفاتورة القديمة وإضافة البنود المحدثة مع ضبط الكميات الجديدة
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
            SET quantity = quantity + ? 
            WHERE id = ?
          ''', [newQtyChange, prodId]);
        }
      }

      // 4. تطبيق تأثير رصيد العميل الجديد بناءً على المبلغ المتبقي الجديد
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
