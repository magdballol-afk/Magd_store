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
    // جدول جهات الاتصال (العملاء والموردين)
    await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // جدول حركات الصندوق
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
  }

  // ==========================================
  // دوال حركات الصندوق (Cash Transactions)
  // ==========================================

  // إضافة حركة صندوق جديدة
  Future<int> insertCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('cash_transactions', row);
  }

  // قراءة كل حركات الصندوق
  Future<List<Map<String, dynamic>>> getCashTransactions() async {
    final db = await instance.database;
    return await db.query('cash_transactions', orderBy: 'id DESC');
  }

  // تعديل حركة صندوق
  Future<int> updateCashTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    final id = row['id'];
    return await db.update(
      'cash_transactions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // حذف حركة صندوق
  Future<int> deleteCashTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cash_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // دوال جهات الاتصال والرصيد (Contacts & Balance)
  // ==========================================

  // تحديث رصيد الحساب (إضافة/خصم مبلغ)
  Future<int> updateContactBalance(int contactId, double adjustment) async {
    final db = await instance.database;
    return await db.rawUpdate(
      'UPDATE contacts SET balance = balance + ? WHERE id = ?',
      [adjustment, contactId],
    );
  }

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
