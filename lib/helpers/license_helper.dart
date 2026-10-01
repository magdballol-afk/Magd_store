import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LicenseHelper {
  static Database? _database;

  // جلب أو إنشاء قاعدة البيانات المحلية
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app_license.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // إنشاء جدول الحسابات المصرح لها
        await db.execute('''
          CREATE TABLE licenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            registered_device_id TEXT
          )
        ''');

        // 🔑 إدخال اسم المستخدم وكلمة السر المسبقة التي تنشئها أنت للزبائن
        // يمكنك إدخال أكثر من حساب هنا
        await db.insert('licenses', {
          'username': 'basel',
          'password': 'basel123',
          'registered_device_id': null // يكون فارغاً في البداية حتى يدخله الزبون
        });
      },
    );
  }

  // جلب معرّف الجهاز الحالي
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "UNKNOWN_IOS";
      }
    } catch (_) {}
    return "UNKNOWN_DEVICE";
  }

  // دالة التحقق من حالة الترخيص عند فتح التطبيق
  static Future<bool> isAppLicensed() async {
    final db = await database;
    String currentDeviceId = await getDeviceId();

    // البحث عن أي حساب مرتبط بهذا الجهاز تحديداً
    List<Map<String, dynamic>> result = await db.query(
      'licenses',
      where: 'registered_device_id = ?',
      whereArgs: [currentDeviceId],
    );

    return result.isNotEmpty;
  }

  // دالة تفعيل التطبيق باسم المستخدم وكلمة السر
  static Future<String> activateApp(String username, String password) async {
    final db = await database;
    String currentDeviceId = await getDeviceId();

    // 1. البحث عن الحساب برقم المستخدم وكلمة السر
    List<Map<String, dynamic>> result = await db.query(
      'licenses',
      where: 'username = ? AND password = ?',
      whereArgs: [username.trim(), password.trim()],
    );

    if (result.isEmpty) {
      return "اسم المستخدم أو كلمة السر غير صحيحة";
    }

    var account = result.first;
    String? registeredDeviceId = account['registered_device_id'];

    // 2. التحقق مما إذا كان الحساب قد تم تفعيله سابقاً على جهاز آخر
    if (registeredDeviceId != null && registeredDeviceId != currentDeviceId) {
      return "هذا الحساب مفعّل مسبقاً على جهاز آخر ولا يمكن استخدامه هنا!";
    }

    // 3. ربط الجهاز الحالي بالحساب في حال كان التفعيل لأول مرة
    await db.update(
      'licenses',
      {'registered_device_id': currentDeviceId},
      where: 'username = ?',
      whereArgs: [username.trim()],
    );

    return "SUCCESS";
  }
}
