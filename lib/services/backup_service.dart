import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  // اسم ملف قاعدة البيانات الخاص بالمشروع
  static const String _dbName = 'app_database.db';

  /// 1. إنشاء نسخة احتياطية ومشاركتها
  static Future<void> createAndShareBackup(BuildContext context) async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = p.join(dbFolder, _dbName);
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        if (context.mounted) {
          _showSnackBar(context, 'لا توجد قاعدة بيانات حالية للنسخ الاحتياطي', isError: true);
        }
        return;
      }

      // تجهيز اسم ملف النسخة الاحتياطية متضمناً التاريخ والوقت
      final now = DateTime.now();
      final dateStr =
          "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}";
      final tempDir = Directory.systemTemp;
      final backupPath = p.join(tempDir.path, 'backup_store_$dateStr.db');

      // نسخ ملف قاعدة البيانات
      final backupFile = await dbFile.copy(backupPath);

      // مشاركة الملف عبر الواتساب أو حفظه على الجهاز/Drive
      final xFile = XFile(backupFile.path);
      await Share.shareXFiles(
        [xFile],
        text: 'النسخة الاحتياطية لنظام إدارة المبيعات والمستودع - $dateStr',
      );

      if (context.mounted) {
        _showSnackBar(context, 'تمت عملية إعداد النسخة الاحتياطية بنجاح');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'حدث خطأ أثناء إنشاء النسخة الاحتياطية: $e', isError: true);
      }
    }
  }

  /// 2. استرجاع نسخة احتياطية من ملف خارجي
  static Future<void> restoreBackup(BuildContext context) async {
    try {
      // فتح واجهة اختيار الملفات من الهاتف
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final selectedFilePath = result.files.single.path!;
        final selectedFile = File(selectedFilePath);

        // التأكد من أن الملف ينتهي بـ .db
        if (!selectedFilePath.endsWith('.db')) {
          if (context.mounted) {
            _showSnackBar(context, 'الرجاء اختيار ملف نسخة احتياطية صالحة (امتداد .db)', isError: true);
          }
          return;
        }

        final dbFolder = await getDatabasesPath();
        final dbPath = p.join(dbFolder, _dbName);

        // استبدال قاعدة البيانات الحالية بالملف المسترجع
        await selectedFile.copy(dbPath);

        if (context.mounted) {
          _showSnackBar(context, 'تمت استعادة البيانات بنجاح! يرجى إغلاق التطبيق وإعادة فتحه لتحديث البيانات.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'حدث خطأ أثناء استعادة النسخة الاحتياطية: $e', isError: true);
      }
    }
  }

  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
