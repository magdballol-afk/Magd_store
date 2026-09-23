import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class PrintService {
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  // ==========================================
  //  بيانات المنشأة / الشركة (يمكنك تعديلها هنا)
  // ==========================================
  static const String companyName = "شركة التجارة العامة";
  static const String taxNumber = "الرقم الضريبي: 123456789";
  static const String companyPhone = "هاتف: 0912345678 / 011123456";
  static const String companyAddress = "العنوان: الشارع العام - المركز الرئيسي";

  /// دالة للتحقق واختيار الطابعة ثم الطباعة
  static Future<void> selectAndPrintInvoice({
    required BuildContext context,
    required String invoiceType, // "فاتورة مبيعات" أو "فاتورة مشتريات"
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required double paidAmount,
    required double remainingAmount,
    String currency = "ل.س",
    bool is80mm = true, // افتراضياً 80mm لطابعة Bixolon
  }) async {
    bool? isConnected = await _bluetooth.isConnected;

    if (isConnected != true) {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();

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
              title: const Text('اختر طابعة البلوتوث (Bixolon)'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.name ?? 'جهاز غير معروف'),
                      subtitle: Text(device.address ?? ''),
                      leading: const Icon(Icons.print),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await _bluetooth.connect(device);
                          if (context.mounted) {
                            _printContent(
                              context: context,
                              invoiceType: invoiceType,
                              invoiceNumber: invoiceNumber,
                              customerName: customerName,
                              items: items,
                              totalPrice: totalPrice,
                              paidAmount: paidAmount,
                              remainingAmount: remainingAmount,
                              currency: currency,
                              is80mm: is80mm,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل الاتصال بالطابعة: $e')),
                            );
                          }
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
        currency: currency,
        is80mm: is80mm,
      );
    }
  }

  /// تنفيذ أوامر طباعة الفاتورة وضبط العرض بـ 80mm (BIXOLON)
  static Future<void> _printContent({
    required BuildContext context,
    required String invoiceType,
    required String invoiceNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required double paidAmount,
    required double remainingAmount,
    required String currency,
    required bool is80mm,
  }) async {
    try {
      // إعداد عرض السطر (48 حرفاً لقياس 80mm / و 32 حرفاً لقياس 58mm)
      final int paperWidth = is80mm ? 48 : 32;

      _bluetooth.printNewLine();

      // 1. ترويسة معلومات الشركة (في المنتصف)
      _bluetooth.printCustom(companyName, 2, 1); // خط عريض وكبير في الوسط
      _bluetooth.printCustom(taxNumber, 0, 1);
      _bluetooth.printCustom(companyPhone, 0, 1);
      _bluetooth.printCustom(companyAddress, 0, 1);
      _bluetooth.printCustom("=" * paperWidth, 0, 1);

      // 2. تفاصيل الفاتورة والعميل
      _bluetooth.printCustom(invoiceType, 2, 1); // نوع الفاتورة (مبيعات / مشتريات)
      _bluetooth.printCustom("رقم الفاتورة: #$invoiceNumber", 1, 1);
      _bluetooth.printCustom("التاريخ: ${DateTime.now().toString().split(' ')[0]}", 0, 1);
      _bluetooth.printCustom("العميل: $customerName", 1, 1);
      _bluetooth.printCustom("-" * paperWidth, 0, 1);

      // 3. جدول المواد: المادة | الكمية | السعر | الإجمالي
      if (is80mm) {
        _bluetooth.printCustom("المادة                   الكمية   السعر    الإجمالي", 1, 0);
      } else {
        _bluetooth.printCustom("المادة           الكمية   السعر", 1, 0);
      }
      _bluetooth.printCustom("-" * paperWidth, 0, 1);

      for (var item in items) {
        String name = (item['name'] ?? '').toString();
        double qty = double.tryParse((item['quantity'] ?? 1).toString()) ?? 1.0;
        double price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
        double lineTotal = qty * price;

        if (name.length > 18) {
          name = name.substring(0, 18);
        }

        if (is80mm) {
          String pName = name.padRight(22);
          String pQty = qty.toStringAsFixed(1).padLeft(6);
          String pPrice = price.toStringAsFixed(0).padLeft(8);
          String pTotal = lineTotal.toStringAsFixed(0).padLeft(10);
          _bluetooth.printCustom("$pName $pQty $pPrice $pTotal", 0, 0);
        } else {
          String pName = name.padRight(14);
          String pQty = qty.toStringAsFixed(1).padLeft(5);
          String pTotal = lineTotal.toStringAsFixed(0).padLeft(8);
          _bluetooth.printCustom("$pName $pQty $pTotal", 0, 0);
        }
      }

      _bluetooth.printCustom("-" * paperWidth, 0, 1);

      // 4. المجاميع والمدفوعات
      _bluetooth.printCustom("المجموع الإجمالي: ${totalPrice.toStringAsFixed(2)} $currency", 1, 2);
      _bluetooth.printCustom("المدفوع نقداً   : ${paidAmount.toStringAsFixed(2)} $currency", 0, 2);
      _bluetooth.printCustom("المتبقي         : ${remainingAmount.toStringAsFixed(2)} $currency", 1, 2);

      _bluetooth.printCustom("=" * paperWidth, 0, 1);
      _bluetooth.printCustom("شكراً لزيارتكم", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut(); // قطع الورقة تلقائياً للطابعات الداعمة للقطع
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الطباعة: $e')),
        );
      }
    }
  }
}
