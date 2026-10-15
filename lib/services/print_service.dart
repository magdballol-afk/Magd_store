import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

class PrintService {
  // ==========================================
  // بيانات المنشأة / الشركة
  // ==========================================
  static const String companyName = "شركة التجارة العامة";
  static const String taxNumber = "الرقم الضريبي: 123456789";
  static const String companyPhone = "هاتف: 0912345678 / 011123456";
  static const String companyAddress = "العنوان: الشارع العام - المركز الرئيسي";

  /// دالة محسنة لتحويل النصوص العربية إلى صور عالية الوضوح تناسب طابعة PT-220 (58mm)
  static Future<img.Image?> _textToImage(String text, {int fontSize = 24, bool bold = false, int width = 384, ui.TextAlign align = ui.TextAlign.center}) async {
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: align,
        fontWeight: bold ? ui.FontWeight.bold : ui.FontWeight.w600,
        fontSize: fontSize.toDouble(),
      ),
    );
    
    pb.pushStyle(ui.TextStyle(color: const ui.Color(0xFF000000)));
    pb.addText(text);
    
    final ui.Paragraph paragraph = pb.build();
    paragraph.layout(ui.ParagraphConstraints(width: width.toDouble()));

    final int height = paragraph.height.ceil();
    if (height <= 0 || width <= 0) return null;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromPoints(Offset.zero, Offset(width.toDouble(), height.toDouble())));
    
    // خلفية بيضاء صافية للصورة
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = const ui.Color(0xFFFFFFFF));
    canvas.drawParagraph(paragraph, Offset.zero);

    final ui.Image image = await recorder.endRecording().toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) return null;

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
    bool is58mm = true, // افتراضياً للطابعة PT-220 بحجم 58 ملم
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

  /// إرسال أوامر الطباعة بدقة متناهية لطابعة PT-220
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

      // عرض البكسل القياسي لطابعة 58 مم (384 نقطة) لملء عرض الورقة تماماً دون فراغات جانبية
      final int pageWidth = is58mm ? 384 : 576; 

      // 1. ترويسة الشركة
      img.Image? compImg = await _textToImage(companyName, fontSize: 28, bold: true, width: pageWidth, align: ui.TextAlign.center);
      if (compImg != null) bytes += generator.image(compImg);

      img.Image? taxImg = await _textToImage(taxNumber, fontSize: 18, width: pageWidth, align: ui.TextAlign.center);
      if (taxImg != null) bytes += generator.image(taxImg);

      img.Image? phoneImg = await _textToImage(companyPhone, fontSize: 18, width: pageWidth, align: ui.TextAlign.center);
      if (phoneImg != null) bytes += generator.image(phoneImg);

      img.Image? addrImg = await _textToImage(companyAddress, fontSize: 18, width: pageWidth, align: ui.TextAlign.center);
      if (addrImg != null) bytes += generator.image(addrImg);

      bytes += generator.text("-" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));

      // 2. تفاصيل الفاتورة والعميل (محاذاة لليمين لتناسب شكل الفاتورة النظامي)
      img.Image? typeImg = await _textToImage(invoiceType, fontSize: 24, bold: true, width: pageWidth, align: ui.TextAlign.right);
      if (typeImg != null) bytes += generator.image(typeImg);

      img.Image? invNumImg = await _textToImage("رقم الفاتورة: #$invoiceNumber", fontSize: 20, width: pageWidth, align: ui.TextAlign.right);
      if (invNumImg != null) bytes += generator.image(invNumImg);

      img.Image? dateImg = await _textToImage("التاريخ: ${DateTime.now().toString().split(' ')[0]}", fontSize: 20, width: pageWidth, align: ui.TextAlign.right);
      if (dateImg != null) bytes += generator.image(dateImg);

      img.Image? custImg = await _textToImage("العميل: $customerName", fontSize: 20, bold: true, width: pageWidth, align: ui.TextAlign.right);
      if (custImg != null) bytes += generator.image(custImg);

      bytes += generator.text("-" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));

      // 3. المواد المضافة بالفاتورة
      for (var item in items) {
        String name = (item['name'] ?? '').toString();
        double qty = double.tryParse((item['quantity'] ?? 1).toString()) ?? 1.0;
        double price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
        double lineTotal = qty * price;

        img.Image? itemNameImg = await _textToImage("• $name", fontSize: 22, bold: true, width: pageWidth, align: ui.TextAlign.right);
        if (itemNameImg != null) bytes += generator.image(itemNameImg);

        String detailsText = "الكمية: ${qty.toStringAsFixed(1)}  |  السعر: ${price.toStringAsFixed(0)}  |  الإجمالي: ${lineTotal.toStringAsFixed(0)}";
        img.Image? itemDetailsImg = await _textToImage(detailsText, fontSize: 18, width: pageWidth, align: ui.TextAlign.right);
        if (itemDetailsImg != null) bytes += generator.image(itemDetailsImg);

        bytes += generator.text("-" * 24, styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.text("-" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));

      // 4. المجاميع النهائية
      String totalText = "المجموع الإجمالي: ${totalPrice.toStringAsFixed(2)} $currency";
      img.Image? totalImg = await _textToImage(totalText, fontSize: 20, bold: true, width: pageWidth, align: ui.TextAlign.right);
      if (totalImg != null) bytes += generator.image(totalImg);

      String paidText = "المدفوع نقداً: ${paidAmount.toStringAsFixed(2)} $currency";
      img.Image? paidImg = await _textToImage(paidText, fontSize: 20, width: pageWidth, align: ui.TextAlign.right);
      if (paidImg != null) bytes += generator.image(paidImg);

      String remainingText = "المتبقي بالفاتورة: ${remainingAmount.toStringAsFixed(2)} $currency";
      img.Image? remainingImg = await _textToImage(remainingText, fontSize: 20, bold: true, width: pageWidth, align: ui.TextAlign.right);
      if (remainingImg != null) bytes += generator.image(remainingImg);

      if (customerBalance != null) {
        String balanceText = "الرصيد الحالي: ${customerBalance.toStringAsFixed(2)} $currency";
        img.Image? balanceImg = await _textToImage(balanceText, fontSize: 20, width: pageWidth, align: ui.TextAlign.right);
        if (balanceImg != null) bytes += generator.image(balanceImg);
      }

      bytes += generator.text("=" * (is58mm ? 32 : 48), styles: const PosStyles(align: PosAlign.center));
      
      img.Image? thanksImg = await _textToImage("شكراً لزيارتكم", fontSize: 24, bold: true, width: pageWidth, align: ui.TextAlign.center);
      if (thanksImg != null) bytes += generator.image(thanksImg);

      bytes += generator.feed(3);

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
