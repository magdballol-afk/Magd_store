import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class FiscalYearService {
  /// إظهار حوار التأكيد وتنفيذ عملية التدوير
  static Future<void> showRolloverDialog(BuildContext context) async {
    final TextEditingController newYearController = TextEditingController(
      text: (DateTime.now().year + 1).toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.published_with_changes_rounded, color: Color(0xFFE53935)),
              SizedBox(width: 8),
              Text('تدوير السنة المالية', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تنبيه: سيتم إغلاق حسابات السنة الحالية وتدوير الأرصدة النهائية (العملاء، الموردين، الصندوق، والمستودع) كأرصدة افتتاحية للسنة الجديدة، وحذف جميع الفواتير وحركات الصندوق القديمة.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السنة المالية الجديدة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final newYear = newYearController.text.trim();
                if (newYear.isEmpty) return;

                Navigator.pop(dialogContext);
                await _executeRollover(context, newYear);
              },
              child: const Text('تأكيد التدوير'),
            ),
          ],
        );
      },
    );
  }

  /// تنفيذ عملية تدوير قاعدة البيانات
  static Future<void> _executeRollover(BuildContext context, String newYear) async {
    // 1. إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تدوير الأرصدة وإغلاق السنة...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 2. تنفيذ التدوير الفعلي في قاعدة البيانات
      await DatabaseHelper.instance.executeFiscalYearRollover(newYear);

      if (context.mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت عملية التدوير للسنة $newYear وتصفير الحركة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التدوير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
