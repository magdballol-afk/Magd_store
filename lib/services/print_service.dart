import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PrintService {
  // ==========================================
  // بيانات المنشأة / الشركة
  // ==========================================
  static const String companyName = "شركة التجارة العامة";
  static const String taxNumber = "الرقم الضريبي: 123456789";
  static const String companyPhone = "هاتف: 0912345678 / 011123456";
  static const String companyAddress = "العنوان: الشارع العام - المركز الرئيسي";

  /// دالة مساعدة لتنظيف النصوص من الرموز الخاصة وعلامات الترقيم المسببة لأخطاء الطباعة
  static String cleanText(String text) {
    if (text.isEmpty) return "";
    // إزالة علامات التنصيص المزدوجة، الفردية، والرموز التي قد تسبب استثناءات في ترميز الطابعة
    return text.replaceAll(RegExp(r'["„“”«»\x00-\x1F\x7F-\x9F]'), '').trim();
  }

  /// دالة اختيار الطابعة والطباعة
  static Future<void> selectAndPrintInvoice({
    required BuildContext context,
    required String invoiceType,
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required double paidAmount,
    required double remainingAmount,
    double? customerBalance,
    String currency = "",
    bool is58mm = false, // 👈 حدد true لـ PT-220 (58mm) و false لـ TYSSO (80mm)
  }) async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected) {
      List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;

      if (devices.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على أجهزة بلوتوث مقترنة')),
          );
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('اختر طابعة البلوتوث'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.macAdress),
                      leading: const Icon(Icons.print),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        bool result = await PrintBluetoothThermal.connect(
                          macPrinterAddress: device.macAdress,
                        );
                        if (result && context.mounted) {
                          _printContent(
                            context: context,
                            invoiceType: invoiceType,
                            invoiceNumber: invoiceNumber,
                            customerName: customerName,
                            items: items,
                            totalPrice: totalPrice,
                            paidAmount: paidAmount,
                            remainingAmount: remainingAmount,
                            customerBalance: customerBalance,
                            currency: currency,
                            is58mm: is58mm,
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('فشل الاتصال بالطابعة')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      }
    } else {
      _printContent(
        context: context,
        invoiceType: invoiceType,
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        items: items,
        totalPrice: totalPrice,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        customerBalance: customerBalance,
        currency: currency,
        is58mm: is58mm,
      );
    }
  }

  /// إرسال أوامر الطباعة مع معالجة الترميز العربي وتنظيف النصوص الآمنة ESC/POS
  static Future<void> _printContent({
    required BuildContext context,
    required String invoiceType,
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required double paidAmount,
    required double remainingAmount,
    double? customerBalance,
    required String currency,
    required bool is58mm,
  }) async {
    try {
      // 1. تحميل مواصفات الطابعة الحرارية Standard ESC/POS
      final profile = await CapabilityProfile.load();
      final paperSize = is58mm ? PaperSize.mm58 : PaperSize.mm80;
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];

      // 2. ضبط الترميز وتصفير الإعدادات
      bytes += generator.setGlobalCodeTable('CP864');
      bytes += generator.reset();

      final int paperWidth = is58mm ? 32 : 48;
      final String currSuffix = currency.trim().isNotEmpty ? " ${cleanText(currency)}" : "";

      // 3. بناء الفاتورة سطر بسطر مع تنظيف النصوص لمنع أخطاء الرموز الخاصة
      bytes += generator.text(cleanText(companyName), styles: const PosStyles(align: PosAlign.center, bold: true, codeTable: 'CP864'));
      bytes += generator.text(cleanText(taxNumber), styles: const PosStyles(align: PosAlign.center, codeTable: 'CP864'));
      bytes += generator.text(cleanText(companyPhone), styles: const PosStyles(align: PosAlign.center, codeTable: 'CP864'));
      bytes += generator.text(cleanText(companyAddress), styles: const PosStyles(align: PosAlign.center, codeTable: 'CP864'));
      bytes += generator.text("-" * paperWidth, styles: const PosStyles(align: PosAlign.center));

      bytes += generator.text(cleanText(invoiceType), styles: const PosStyles(align: PosAlign.right, bold: true, codeTable: 'CP864'));
      bytes += generator.text("رقم الفاتورة: #${cleanText(invoiceNumber)}", styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'));
      bytes += generator.text("التاريخ: ${DateTime.now().toString().split(' ')[0]}", styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'));
      bytes += generator.text("العميل: ${cleanText(customerName)}", styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'));
      bytes += generator.text("-" * paperWidth, styles: const PosStyles(align: PosAlign.center));

      // طباعة تفاصيل المواد
      for (var item in items) {
        String name = cleanText((item['name'] ?? '').toString());
        double qty = double.tryParse((item['quantity'] ?? 1).toString()) ?? 1.0;
        double price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
        double lineTotal = qty * price;

        bytes += generator.text(name, styles: const PosStyles(align: PosAlign.right, bold: true, codeTable: 'CP864'));
        bytes += generator.text(
          "الكمية: ${qty.toStringAsFixed(1)} | السعر: ${price.toStringAsFixed(0)} | الإجمالي: ${lineTotal.toStringAsFixed(0)}",
          styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'),
        );
        bytes += generator.text("-" * 20, styles: const PosStyles(align: PosAlign.right));
      }

      bytes += generator.text("-" * paperWidth, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("المجموع الإجمالي: ${totalPrice.toStringAsFixed(2)}$currSuffix", styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'));
      bytes += generator.text("المدفوع نقداً: ${paidAmount.toStringAsFixed(2)}$currSuffix", styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'));
      bytes += generator.text("المتبقي بالفاتورة: ${remainingAmount.toStringAsFixed(2)}$currSuffix", styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'));

      if (customerBalance != null) {
        bytes += generator.text("الرصيد الحالي: ${customerBalance.toStringAsFixed(2)}$currSuffix", styles: const PosStyles(align: PosAlign.right, codeTable: 'CP864'));
      }

      bytes += generator.text("=" * paperWidth, styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("شكراً لزيارتكم", styles: const PosStyles(align: PosAlign.center, bold: true, codeTable: 'CP864'));

      bytes += generator.feed(2);

      // أمر قطع الورق التلقائي للطابعات الكبيرة التي تدعم القطع
      if (!is58mm) {
        bytes += generator.cut();
      }

      // 5. إرسال البايتات المرمزة إلى الطابعة
      await PrintBluetoothThermal.writeBytes(bytes);

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الطباعة: $e')),
        );
      }
    }
  }
}
