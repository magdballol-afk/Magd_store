import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrintService {
  // ==========================================
  // بيانات المنشأة / الشركة
  // ==========================================
  static const String companyName = "شركة التجارة العامة";
  static const String taxNumber = "الرقم الضريبي: 123456789";
  static const String companyPhone = "هاتف: 0912345678 / 011123456";
  static const String companyAddress = "العنوان: الشارع العام - المركز الرئيسي";

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
    bool is58mm = false, // خيار لتحديد قياس الطابعة (80mm أو 58mm)
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

  /// إرسال أوامر الطباعة
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
      final StringBuffer receipt = StringBuffer();
      
      // تحديد عرض الورق بناءً على نوع الطابعة
      final int paperWidth = is58mm ? 32 : 48;
      final String currSuffix = currency.trim().isNotEmpty ? " $currency" : "";

      // 1. ترويسة معلومات الشركة
      receipt.writeln(companyName);
      receipt.writeln(taxNumber);
      receipt.writeln(companyPhone);
      receipt.writeln(companyAddress);
      receipt.writeln("=" * paperWidth);

      // 2. تفاصيل الفاتورة والعميل
      receipt.writeln(invoiceType);
      receipt.writeln("رقم الفاتورة: #$invoiceNumber");
      receipt.writeln("التاريخ: ${DateTime.now().toString().split(' ')[0]}");
      receipt.writeln("العميل: $customerName");
      receipt.writeln("-" * paperWidth);

      // 3. جدول المواد (تنسيق متجاوب حسب عرض الورق)
      if (is58mm) {
        receipt.writeln("المادة           الكمية السعر الإجمالي");
        receipt.writeln("-" * paperWidth);

        for (var item in items) {
          String name = (item['name'] ?? '').toString();
          double qty = double.tryParse((item['quantity'] ?? 1).toString()) ?? 1.0;
          double price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
          double lineTotal = qty * price;

          if (name.length > 12) name = name.substring(0, 12);

          String pName = name.padRight(13);
          String pQty = qty.toStringAsFixed(1).padLeft(5);
          String pPrice = price.toStringAsFixed(0).padLeft(6);
          String pTotal = lineTotal.toStringAsFixed(0).padLeft(7);

          receipt.writeln("$pName $pQty $pPrice $pTotal");
        }
      } else {
        receipt.writeln("المادة                   الكمية   السعر    الإجمالي");
        receipt.writeln("-" * paperWidth);

        for (var item in items) {
          String name = (item['name'] ?? '').toString();
          double qty = double.tryParse((item['quantity'] ?? 1).toString()) ?? 1.0;
          double price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
          double lineTotal = qty * price;

          if (name.length > 18) name = name.substring(0, 18);

          String pName = name.padRight(22);
          String pQty = qty.toStringAsFixed(1).padLeft(6);
          String pPrice = price.toStringAsFixed(0).padLeft(8);
          String pTotal = lineTotal.toStringAsFixed(0).padLeft(10);

          receipt.writeln("$pName $pQty $pPrice $pTotal");
        }
      }

      // 4. المجاميع والختام
      receipt.writeln("-" * paperWidth);
      receipt.writeln("المجموع الإجمالي: ${totalPrice.toStringAsFixed(2)}$currSuffix");
      receipt.writeln("المدفوع نقداً   : ${paidAmount.toStringAsFixed(2)}$currSuffix");
      receipt.writeln("المتبقي بالفاتورة: ${remainingAmount.toStringAsFixed(2)}$currSuffix");

      if (customerBalance != null) {
        receipt.writeln("-" * paperWidth);
        receipt.writeln("الرصيد الحالي   : ${customerBalance.toStringAsFixed(2)}$currSuffix");
      }

      receipt.writeln("=" * paperWidth);
      receipt.writeln("شكراً لزيارتكم\n\n\n");

      // إرسال البيانات
      List<int> bytes = receipt.toString().codeUnits;
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
