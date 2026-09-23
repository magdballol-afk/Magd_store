import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrintService {
  /// 1. البحث عن أجهزة البلوتوث المقترنة واختيار الطابعة
  static Future<void> selectAndPrintInvoice({
    required BuildContext context,
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
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

    // عرض نافذة لاختيار الطابعة (مثل BIXOLON)
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
                            invoiceNumber: invoiceNumber,
                            customerName: customerName,
                            items: items,
                            totalPrice: totalPrice,
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

  /// 2. الاتصال بالطابعة وإرسال بيانات الفاتورة
  static Future<void> _connectAndPrint({
    required BuildContext context,
    required String macAddress,
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String currency,
  }) async {
    try {
      // الاتصال بالطابعة عبر عنوان MAC
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);

      if (result) {
        // بناء نص الفاتورة بتنسيق حراري مرتب
        StringBuffer bytes = StringBuffer();
        
        bytes.writeln("================================");
        bytes.writeln("       فاتورة مبيعات           ");
        bytes.writeln("================================");
        bytes.writeln("رقم الفاتورة : $invoiceNumber");
        bytes.writeln("العميل       : $customerName");
        bytes.writeln("التاريخ      : ${DateTime.now().toString().split(' ')[0]}");
        bytes.writeln("--------------------------------");
        bytes.writeln("المادة          العدد     السعر");
        bytes.writeln("--------------------------------");

        for (var item in items) {
          String name = item['name'] ?? '';
          int qty = item['quantity'] ?? 1;
          double price = (item['price'] as num).toDouble();
          bytes.writeln("$name\n                 $qty   x   $price");
        }

        bytes.writeln("--------------------------------");
        bytes.writeln("الإجمالي: $totalPrice $currency");
        bytes.writeln("================================");
        bytes.writeln("       شكراً لزيارتكم!          \n\n\n");

        // إرسال النص للطباعة
        await PrintBluetoothThermal.writeBytes(bytes.toString().codeUnits);
        
        // قطع الاتصال تلقائياً بعد الانتهاء
        await PrintBluetoothThermal.disconnect;

        if (context.mounted) {
          _showSnackBar(context, 'تمت إرسال الفاتورة للطابعة بنجاح');
        }
      } else {
        if (context.mounted) {
          _showSnackBar(context, 'فشل الاتصال بالطابعة المحددة', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'حدث خطأ أثناء الطباعة: $e', isError: true);
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
