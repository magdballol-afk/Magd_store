import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart'; // حزمة البلوتوث

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // إعدادات البلوتوث والطابعة
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  // عناصر الفاتورة
  String selectedCurrency = 'ليرة سورية';
  bool isDiscountAmount = true; // مبلغ أم نسبة مئوية
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.0');
  final TextEditingController _paidController = TextEditingController();

  // بيانات حسابية تجريبية
  double subtotal = 0.0;
  double totalDiscount = 0.0;
  double netTotal = 0.0;
  double previousBalance = 0.0;
  double remainingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  // تهيئة البلوتوث وجلب الأجهزة المقترنة
  void _initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      print("خطأ في جلب أجهزة البلوتوث: $e");
    }

    if (mounted) {
      setState(() {
        _devices = devices;
        _isConnected = isConnected ?? false;
      });
    }
  }

  // دالة اختيار الطابعة والاتصال بها
  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر طابعة البلوتوث', textAlign: TextAlign.right),
          content: DropdownButton<BluetoothDevice>(
            value: _selectedDevice,
            hint: const Text('اختر الطابعة'),
            isExpanded: true,
            items: _devices.map((device) {
              return DropdownMenuItem(
                value: device,
                child: Text(device.name ?? 'جهاز غير معروف'),
              );
            }).toList(),
            onChanged: (device) {
              setState(() {
                _selectedDevice = device;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedDevice != null) {
                  await bluetooth.connect(_selectedDevice!);
                  setState(() {
                    _isConnected = true;
                  });
                  Navigator.pop(context);
                  _printReceipt(); // طباعة الفاتورة فور الاتصال
                }
              },
              child: const Text('اتصال وطباعة'),
            ),
          ],
        );
      },
    );
  }

  // دالة طباعة الفاتورة حرارياً عبر البلوتوث
  void _printReceipt() async {
    if ((await bluetooth.isConnected) ?? false) {
      // 1. عنوان الفاتورة (منتصف)
      bluetooth.printCustom("فاتورة مبيعات", 3, 1);
      bluetooth.printNewLine();

      // 2. تفاصيل العميل والعملة
      bluetooth.printLeftRight("العميل:", _customerController.text.isEmpty ? "عميل نقدي" : _customerController.text, 1);
      bluetooth.printLeftRight("العملة:", selectedCurrency, 1);
      bluetooth.printCustom("--------------------------------", 1, 1);

      // 3. الحسابات والأسعار
      bluetooth.printLeftRight("المجموع الفرعي:", "$subtotal $selectedCurrency", 1);
      bluetooth.printLeftRight("الخصم الكلي:", "${_discountController.text} $selectedCurrency", 1);
      bluetooth.printLeftRight("صافي الفاتورة:", "$netTotal $selectedCurrency", 1);
      bluetooth.printLeftRight("الدفعة المقبوضة:", "${_paidController.text} $selectedCurrency", 1);
      bluetooth.printLeftRight("الرصيد المتبقي:", "$remainingBalance $selectedCurrency", 1);

      bluetooth.printCustom("--------------------------------", 1, 1);
      bluetooth.printCustom("شكراً لزيارتكم", 2, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut(); // قطع الورقة إن كانت الطابعة تدعم ذلك
    } else {
      _showPrinterDialog(); // إذا لم يكن متصلاً، افحص وافتح قائمة الطابعات
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _discountController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. عملة الفاتورة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('(\$) دولار'),
                      selected: selectedCurrency == 'دولار',
                      onSelected: (selected) {
                        setState(() => selectedCurrency = 'دولار');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('ليرة سورية'),
                      selected: selectedCurrency == 'ليرة سورية',
                      selectedColor: const Color(0xFF0D47A1),
                      labelStyle: TextStyle(color: selectedCurrency == 'ليرة سورية' ? Colors.white : Colors.black),
                      onSelected: (selected) {
                        setState(() => selectedCurrency = 'ليرة سورية');
                      },
                    ),
                  ],
                ),
                const Text(':عملة الفاتورة', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // 2. البحث عن اسم العميل
            TextFormField(
              controller: _customerController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث أو أدخل اسم العميل...',
                prefixIcon: const Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // 3. زر إضافة منتج للفاتورة
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0D47A1)),
              label: const Text('إضافة منتج للفاتورة (مفرق)', style: TextStyle(color: Color(0xFF0D47A1), fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 16),

            // 4. قائمة المنتجات المضافة
            const Align(
              alignment: Alignment.centerRight,
              child: Text('المنتجات المضافة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('لم يتم إضافة أي منتج بعد', style: TextStyle(color: Colors.grey[400])),
            ),
            const SizedBox(height: 20),
            const Divider(),

            // 5. المجموع الفرعي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$subtotal $selectedCurrency', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text(':المجموع الفرعي', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // 6. حسم الفاتورة الكلي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _discountController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                ToggleButtons(
                  isSelected: [isDiscountAmount, !isDiscountAmount],
                  onPressed: (index) {
                    setState(() {
                      isDiscountAmount = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('مبلغ')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('%')),
                  ],
                ),
                const Text(':حسم الفاتورة الكلي', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // 7. صافي الفاتورة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$netTotal $selectedCurrency', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const Text(':صافي الفاتورة', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            // 8. رصيد سابق مترتب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$previousBalance $selectedCurrency', style: const TextStyle(color: Colors.grey)),
                const Text(':رصيد سابق مترتب', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // 9. الدفعة المقبوضة
            TextFormField(
              controller: _paidController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'الدفعة المقبوضة ($selectedCurrency)',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // 10. الرصيد الحالي المتبقي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$remainingBalance $selectedCurrency', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const Text(':الرصيد الحالي المتبقي', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),

            // ================== الأزرار الرئيسية ==================
            Row(
              children: [
                // زر طباعة عبر البلوتوث المضاف
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _showPrinterDialog,
                    icon: const Icon(Icons.print_outlined, color: Colors.white),
                    label: const Text('طباعة', style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // لون مميز لزر الطباعة
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // زر حفظ الفاتورة الرئيسي
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // كود حفظ الفاتورة
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
