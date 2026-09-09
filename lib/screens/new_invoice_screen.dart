import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class NewInvoiceScreen extends StatefulWidget {
  final dynamic existingInvoice;

  const NewInvoiceScreen({Key? key, this.existingInvoice}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // إعدادات البلوتوث والطابعة
  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _selectedDevice;
  bool _isConnected = false;

  // عناصر الفاتورة
  String selectedCurrency = 'ليرة سورية';
  bool isDiscountAmount = true;
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.0');
  final TextEditingController _paidController = TextEditingController();

  // الحسابات
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

  // البحث عن أجهزة البلوتوث المقترنة
  void _initBluetooth() async {
    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    if (result) {
      final List<BluetoothInfo> pairedDevices = await PrintBluetoothThermal.pairedBluetoothDevice;
      if (mounted) {
        setState(() {
          _devices = pairedDevices;
        });
      }
    }
  }

  // نافذة اختيار الطابعة
  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر طابعة البلوتوث', textAlign: TextAlign.right),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return DropdownButton<BluetoothInfo>(
                value: _selectedDevice,
                hint: const Text('اختر الطابعة'),
                isExpanded: true,
                items: _devices.map((device) {
                  return DropdownMenuItem(
                    value: device,
                    child: Text(device.name),
                  );
                }).toList(),
                onChanged: (device) {
                  setDialogState(() {
                    _selectedDevice = device;
                  });
                  setState(() {
                    _selectedDevice = device;
                  });
                },
              );
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
                  final bool connect = await PrintBluetoothThermal.connect(
                    macPrinterAddress: _selectedDevice!.macAdress,
                  );
                  setState(() {
                    _isConnected = connect;
                  });
                  Navigator.pop(context);
                  if (connect) {
                    _printReceipt();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل الاتصال بالطابعة')),
                    );
                  }
                }
              },
              child: const Text('اتصال وطباعة'),
            ),
          ],
        );
      },
    );
  }

  // عملية الطباعة
  void _printReceipt() async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      String receiptText = "فاتورة مبيعات\n";
      receiptText += "العميل: ${_customerController.text.isEmpty ? "عميل نقدي" : _customerController.text}\n";
      receiptText += "العملة: $selectedCurrency\n";
      receiptText += "--------------------------------\n";
      receiptText += "المجموع الفرعي: $subtotal $selectedCurrency\n";
      receiptText += "الخصم الكلي: ${_discountController.text} $selectedCurrency\n";
      receiptText += "صافي الفاتورة: $netTotal $selectedCurrency\n";
      receiptText += "الدفعة المقبوضة: ${_paidController.text} $selectedCurrency\n";
      receiptText += "الرصيد المتبقي: $remainingBalance $selectedCurrency\n";
      receiptText += "--------------------------------\n";
      receiptText += "شكراً لزيارتكم\n\n\n";

      await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 2, text: receiptText),
      );
    } else {
      _showPrinterDialog();
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
            // عملة الفاتورة
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
                      labelStyle: TextStyle(
                        color: selectedCurrency == 'ليرة سورية' ? Colors.white : Colors.black,
                      ),
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

            // اسم العميل
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

            // زر إضافة منتج
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0D47A1)),
              label: const Text(
                'إضافة منتج للفاتورة (مفرق)',
                style: TextStyle(color: Color(0xFF0D47A1), fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 16),

            // قائمة المنتجات
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

            // المجموع الفرعي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$subtotal $selectedCurrency', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text(':المجموع الفرعي', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // حسم الفاتورة الكلي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100,
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

            // صافي الفاتورة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$netTotal $selectedCurrency', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const Text(':صافي الفاتورة', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            // رصيد سابق مترتب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$previousBalance $selectedCurrency', style: const TextStyle(color: Colors.grey)),
                const Text(':رصيد سابق مترتب', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // الدفعة المقبوضة
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

            // الرصيد الحالي المتبقي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$remainingBalance $selectedCurrency', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const Text(':الرصيد الحالي المتبقي', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),

            // الأزرار السفليّة (طباعة وحفظ)
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _showPrinterDialog,
                    icon: const Icon(Icons.print_outlined, color: Colors.white),
                    label: const Text('طباعة', style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    label: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 18, color: Colors.white)),
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
