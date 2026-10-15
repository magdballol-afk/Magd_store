import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

class PrintService {
  // ==========================================
  // بيانات المنشأة / الشركة
  // ==========================================
  static const String companyName = "";
  static const String taxNumber = "الرقم الضريبي: ";
  static const String companyPhone = "هاتف:  ";
  static const String companyAddress = "العنوان: الشارع العام - المركز الرئيسي";

  /// دالة تحويل النص العربي إلى صورة (Bitmap) لطباعتها بدون أخطاء ترميز
  static Future<img.Image?> _textToImage(String text, {int fontSize = 24, bool bold = false, int width = 384}) async {
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
        fontWeight: bold ? ui.FontWeight.bold : ui.FontWeight.normal,
        fontSize: fontSize.toDouble(),
      ),
    );
    
    pb.pushStyle(ui.TextStyle(color: ui.Color(0xFF000000)));
    pb.addText(text);
    
    final ui.Paragraph paragraph = pb.build();
    paragraph.layout(ui.ParagraphConstraints(width: width.toDouble()));

    final int height = paragraph.height.ceil();
    if (height <= 0 || width <= 0) return null;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromPoints(Offset.zero, Offset(width.toDouble(), height.toDouble())));
    
    // خلفية بيضاء للصورة
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = ui.Color(0xFFFFFFFF));
    canvas.drawParagraph(paragraph, Offset(0, 0));

    final ui.Image image = await recorder.endRecording().toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) return null;

    // تحويل البيانات إلى صورة متوافقة مع مكتبة image
    return img.decodeImage(byteData.buffer.asUint8List());
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
    bool is58mm = false,
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

  /// إرسال أوامر الطباعة عبر تحويل النصوص العربية إلى صور لمنع أخطاء الرموز
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
      final profile = await CapabilityProfile.load();
      final paperSize = is58mm ? PaperSize.mm58 : PaperSize.mm80;
      final generator = Generator(paperSize, profile);

      List<int> bytes = [];
      bytes += generator.reset();

      final int pageWidth = is58mm ? 384 : 576; // عرض البكسلات حسب مقاس الورق

      // 1. طباعة ترويسة الشركة كصور لتجنب أي أخطاء عربية
      img.Image? compImg = await _textToImage(companyName, fontSize: 26, bold: true, width: pageWidth);
      if (compImg != null) bytes += generator.image(compImg);

      img.Image? taxImg = await _textToImage(taxNumber, fontSize: 18, width: pageWidth);
      if (taxImg != null) bytes += generator.image(taxImg);

      img.Image? phoneImg = await _textToImage(companyPhone, fontSize: 18, width: pageWidth);
      if (phoneImg != null) bytes += generator.image(phoneImg);

      img.Image? addrImg = await _textToImage(companyAddress, fontSize: 18, width: pageWidth);
      if (addrImg != null) bytes += generator.image(addrImg);

      bytes += generator.text("-" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));

      // 2. معلومات الفاتورة والعميل
      img.Image? typeImg = await _textToImage(invoiceType, fontSize: 22, bold: true, width: pageWidth);
      if (typeImg != null) bytes += generator.image(typeImg);

      img.Image? invNumImg = await _textToImage("رقم الفاتورة: #$invoiceNumber", fontSize: 18, width: pageWidth);
      if (invNumImg != null) bytes += generator.image(invNumImg);

      img.Image? dateImg = await _textToImage("التاريخ: ${DateTime.now().toString().split(' ')[0]}", fontSize: 18, width: pageWidth);
      if (dateImg != null) bytes += generator.image(dateImg);

      img.Image? custImg = await _textToImage("العميل: $customerName", fontSize: 18, width: pageWidth);
      if (custImg != null) bytes += generator.image(custImg);

      bytes += generator.text("-" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));

      // 3. طباعة تفاصيل المواد
      for (var item in items) {
        String name = (item['name'] ?? '').toString();
        double qty = double.tryParse((item['quantity'] ?? 1).toString()) ?? 1.0;
        double price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
        double lineTotal = qty * price;

        img.Image? itemNameImg = await _textToImage(name, fontSize: 20, bold: true, width: pageWidth);
        if (itemNameImg != null) bytes += generator.image(itemNameImg);

        bytes += generator.text(
          "الكمية: ${qty.toStringAsFixed(1)} | السعر: ${price.toStringAsFixed(0)} | الإجمالي: ${lineTotal.toStringAsFixed(0)}",
          styles: const PosStyles(align: PosAlign.right),
        );
        bytes += generator.text("-" * 20, styles: const PosStyles(align: PosAlign.right));
      }

      bytes += generator.text("-" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));

      // 4. المجاميع النهائية
      bytes += generator.text("المجموع الإجمالي: ${totalPrice.toStringAsFixed(2)} $currency", styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text("المدفوع نقداً: ${paidAmount.toStringAsFixed(2)} $currency", styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text("المتبقي بالفاتورة: ${remainingAmount.toStringAsFixed(2)} $currency", styles: const PosStyles(align: PosAlign.right));

      if (customerBalance != null) {
        bytes += generator.text("الرصيد الحالي: ${customerBalance.toStringAsFixed(2)} $currency", styles: const PosStyles(align: PosAlign.right));
      }

      bytes += generator.text("=" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));
      
      img.Image? thanksImg = await _textToImage("شكراً لزيارتكم", fontSize: 22, bold: true, width: pageWidth);
      if (thanksImg != null) bytes += generator.image(thanksImg);

      bytes += generator.feed(2);

      if (!is58mm) {
        bytes += generator.cut();
      }

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
