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
      version: 2, // رفع الإصدار لدعم الجداول والحقول الجديدة
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        subtotal REAL NOT NULL DEFAULT 0.0,
        discount REAL NOT NULL DEFAULT 0.0,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id)
      )
    ''');

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة حقول الحسم والدفعة المسددة عند الترقية تلقائياً
      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN subtotal REAL NOT NULL DEFAULT 0.0');
        await db.execute('ALTER TABLE invoices ADD COLUMN discount REAL NOT NULL DEFAULT 0.0');
        await db.execute('ALTER TABLE invoices ADD COLUMN paid_amount REAL NOT NULL DEFAULT 0.0');
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS invoice_items (
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
  }

  // ==========================================
  // الدوال الأساسية (إدارة المنتجات والعملاء)
  // ==========================================

  Future<int> insertProduct(dynamic data, {String? name, double? price, double? quantity}) async {
    final db = await instance.database;
    if (data is Map<String, dynamic>) return await db.insert('products', data);
    return await db.insert('products', {'name': name ?? '', 'price': price ?? 0.0, 'quantity': quantity ?? 0.0});
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'id DESC');
  }

  Future<int> insertContact(dynamic data, {String? name, String? phone, double? balance}) async {
    final db = await instance.database;
    if (data is Map<String, dynamic>) return await db.insert('contacts', data);
    return await db.insert('contacts', {'name': name ?? '', 'phone': phone ?? '', 'balance': balance ?? 0.0});
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await instance.database;
    return await db.query('contacts', orderBy: 'id DESC');
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
  // إضافة الفاتورة المركبة (مع الحسم والدفعة وحركة المواد والصندوق)
  // ==========================================

  Future<int> addFullInvoice({
    required int? contactId,
    required String contactName,
    required String type, // 'sale' أو 'purchase'
    required double subtotal,
    required double discount,
    required double totalAmount,
    required double paidAmount,
    required List<Map<String, dynamic>> items,
    required String date,
  }) async {
    final db = await instance.database;
    int invoiceId = 0;

    await db.transaction((txn) async {
      // 1. تسجيل الفاتورة الرئيسية
      invoiceId = await txn.insert('invoices', {
        'contact_id': contactId,
        'contact_name': contactName,
        'subtotal': subtotal,
        'discount': discount,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'type': type,
        'date': date,
      });

      // 2. تسجيل عناصر الفاتورة وتحديث مخزون المواد
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

        // تعديل الكمية بالمخزن (تزيد بالمشتريات وتنقص بالمبيعات)
        final double qtyChange = (type == 'sale') ? -item['quantity'] : item['quantity'];
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity + ? WHERE id = ?',
          [qtyChange, item['product_id']],
        );
      }

      // 3. تحديث رصيد الحساب المالي (المتبقي غير المسدد من الفاتورة)
      final double remaining = totalAmount - paidAmount;
      if (contactId != null && remaining != 0) {
        final double balanceChange = (type == 'purchase') ? -remaining : remaining;
        await txn.rawUpdate(
          'UPDATE contacts SET balance = balance + ? WHERE id = ?',
          [balanceChange, contactId],
        );
      }

      // 4. تسجيل حركة الصندوق النقدية (في حال تسديد جزء أو كامل الفاتورة)
      if (paidAmount > 0) {
        await txn.insert('cash_transactions', {
          'contact_id': contactId,
          'contact_name': contactName,
          'type': (type == 'sale') ? 'income' : 'expense',
          'amount': paidAmount,
          'notes': 'دفعة نقدية من فاتورة ${type == 'sale' ? 'مبيعات' : 'مشتريات'} رقم #$invoiceId',
          'date': date,
        });
      }
    });

    return invoiceId;
  }

  // دعم المتطلبات القديمة للأزرار المباشرة
  Future<int> addInvoice(dynamic data, {int? contactId, String? contactName, double? totalAmount, String? type, String? date}) async {
    final db = await instance.database;
    if (data is Map<String, dynamic>) return await db.insert('invoices', data);
    return await db.insert('invoices', {
      'contact_id': contactId,
      'contact_name': contactName ?? 'عام / غير محدد',
      'subtotal': totalAmount ?? 0.0,
      'discount': 0.0,
      'total_amount': totalAmount ?? 0.0,
      'paid_amount': totalAmount ?? 0.0,
      'type': type ?? 'sale',
      'date': date ?? DateTime.now().toString().split(' ')[0],
    });
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'id DESC');
  }
}
