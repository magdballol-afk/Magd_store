import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrintService {
  // البيانات الثابتة للمؤسسة / المحل (يمكنك تعديلها بحسب بياناتك)
  static const String storeName = "مؤسسة بلول التجارية";
  static const String commercialRegister = "CR-1029384"; // السجل التجاري
  static const String taxNumber = "TRN-998877665";      // الرقم الضريبي
  static const String storePhone = "0930000000";

  /// 1. البحث عن أجهزة البلوتوث واختيار الطابعة
  static Future<void> selectAndPrintInvoice({
    required BuildContext context,
    required String invoiceType, // "فاتورة مبيعات" أو "فاتورة مشتريات"
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required double paidAmount,
    required double remainingAmount,
    required String currency,
  }) async {
    // التأكد من تفعيل البلوتوث
    final bool isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!isBluetoothEnabled) {
      if (context.mounted) {
        _showSnackBar(context, 'الرجاء تفعيل البلوتوث أولاً', isError: true);
      }
      return;
    }

    // جلب قائمة الأجهزة المقترنة بالهاتف
    final List<BluetoothInfo> pairedDevices = await PrintBluetoothThermal.pairedBluetooths;

    if (pairedDevices.isEmpty) {
      if (context.mounted) {
        _showSnackBar(context, 'لا توجد أجهزة بلوتوث مقترنة. يرجى إقران الطابعة من إعدادات الهاتف.', isError: true);
      }
      return;
    }

    // عرض نافذة اختيار الطابعة
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (dialogContext) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر طابعة البلوتوث',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pairedDevices.length,
                    itemBuilder: (context, index) {
                      final device = pairedDevices[index];
                      return ListTile(
                        leading: const Icon(Icons.print_rounded, color: Color(0xFF0277BD)),
                        title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(device.macAdress),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          await _connectAndPrint(
                            context: context,
                            macAddress: device.macAdress,
                            invoiceType: invoiceType,
                            invoiceNumber: invoiceNumber,
                            customerName: customerName,
                            items: items,
                            totalPrice: totalPrice,
                            paidAmount: paidAmount,
                            remainingAmount: remainingAmount,
                            currency: currency,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  /// 2. الاتصال بالطابعة وتنسيق الفاتورة الحرارية كاملة
  static Future<void> _connectAndPrint({
    required BuildContext context,
    required String macAddress,
    required String invoiceType,
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required double paidAmount,
    required double remainingAmount,
    required String currency,
  }) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);

      if (result) {
        final now = DateTime.now();
        // تنسيق الوقت التاريخ (مثال: 2026-09-23 | 10:30 PM)
        final String dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final String timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

        StringBuffer sb = StringBuffer();

        // --- هيدر الفاتورة والثوابت ---
        sb.writeln("================================");
        sb.writeln("       $storeName       ");
        sb.writeln("س.ت: $commercialRegister");
        sb.writeln("ر.ض: $taxNumber");
        if (storePhone.isNotEmpty) sb.writeln("هاتف: $storePhone");
        sb.writeln("================================");
        sb.writeln("       *** $invoiceType ***       ");
        sb.writeln("================================");
        sb.writeln("رقم الفاتورة : $invoiceNumber");
        sb.writeln("العميل       : $customerName");
        sb.writeln("التاريخ      : $dateStr");
        sb.writeln("الوقت        : $timeStr");
        sb.writeln("--------------------------------");
        sb.writeln("المادة          العدد     السعر");
        sb.writeln("--------------------------------");

        // --- جدول المواد ---
        for (var item in items) {
          String name = item['name'] ?? item['title'] ?? 'مادة';
          int qty = item['quantity'] ?? item['qty'] ?? 1;
          double price = (item['price'] as num).toDouble();
          double itemTotal = qty * price;

          sb.writeln("$name");
          sb.writeln("  $qty x ${price.toStringAsFixed(0)} = ${itemTotal.toStringAsFixed(0)} $currency");
        }

        // --- تفاصيل المبالغ (الإجمالي / المدفوع / المتبقي) ---
        sb.writeln("--------------------------------");
        sb.writeln("الإجمالي : ${totalPrice.toStringAsFixed(0)} $currency");
        sb.writeln("المدفوع  : ${paidAmount.toStringAsFixed(0)} $currency");
        sb.writeln("المتبقي  : ${remainingAmount.toStringAsFixed(0)} $currency");
        sb.writeln("================================");
        sb.writeln("   شكراً لتعاملكم معنا!   ");
        sb.writeln("\n\n\n"); // مسافة لإخراج الورقة قصها

        // إرسال البيانات للطابعة
        await PrintBluetoothThermal.writeBytes(sb.toString().codeUnits);
        
        // قطع الاتصال تلقائياً
        await PrintBluetoothThermal.disconnect;

        if (context.mounted) {
          _showSnackBar(context, 'تمت طباعة الفاتورة بنجاح');
        }
      } else {
        if (context.mounted) {
          _showSnackBar(context, 'فشل الاتصال بالطابعة', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'خطأ أثناء الطباعة: $e', isError: true);
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
