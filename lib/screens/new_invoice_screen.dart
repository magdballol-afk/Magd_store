import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String invoiceType = 'مبيعات'; // مبيعات أو مشتريات
  String paymentType = 'نقدي'; // نقدي أو أجل (دين)
  String dealingType = 'مفرق'; // مفرق أو جملة
  
  final TextEditingController customerController = TextEditingController();
  final TextEditingController exchangeRateController = TextEditingController(text: '15000');
  final TextEditingController globalDiscountController = TextEditingController(text: '0');

  // قائمة المنتجات داخل الفاتورة
  List<Map<String, dynamic>> invoiceItems = [];

  // قائمة المنتجات المتاحة للاختيار
  final List<Map<String, dynamic>> availableProducts = [
    {'name': 'شامبو بانتين 400 مل', 'price': 12500.0},
    {'name': 'معجون أسنان كولجيت', 'price': 8000.0},
    {'name': 'صابون دوف 100غ', 'price': 4500.0},
    {'name': 'مناديل فاين 500 منديل', 'price': 15000.0},
  ];

  // حساب المجموع الفرعي
  double get subTotal {
    return invoiceItems.fold(0.0, (sum, item) {
      double itemPrice = (item['price'] as double) * (item['quantity'] as int);
      double itemDiscount = item['discount'] as double;
      return sum + (itemPrice - itemDiscount);
    });
  }

  // حساب الإجمالي النهائي بعد الخصم العام
  double get grandTotal {
    double discount = double.tryParse(globalDiscountController.text) ?? 0.0;
    return (subTotal - discount) < 0 ? 0.0 : (subTotal - discount);
  }

  // نافذة إضافة منتج تفاعلية
  void _showAddProductDialog() {
    String selectedProductName = availableProducts[0]['name'];
    double selectedPrice = availableProducts[0]['price'];

    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController priceController = TextEditingController(text: selectedPrice.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('إضافة منتج للفاتورة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // اختيار المادة
                    DropdownButtonFormField<String>(
                      value: selectedProductName,
                      decoration: const InputDecoration(
                        labelText: 'اختر المنتج',
                        border: OutlineInputBorder(),
                      ),
                      items: availableProducts.map((prod) {
                        return DropdownMenuItem<String>(
                          value: prod['name'],
                          child: Text(prod['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final prod = availableProducts.firstWhere((p) => p['name'] == val);
                          setDialogState(() {
                            selectedProductName = val;
                            selectedPrice = prod['price'];
                            priceController.text = selectedPrice.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // إدخال الكمية
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // إدخال السعر
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'السعر (ل.س)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0277BD)),
                  onPressed: () {
                    int qty = int.tryParse(quantityController.text) ?? 1;
                    double price = double.tryParse(priceController.text) ?? 0.0;

                    if (qty > 0 && price >= 0) {
                      setState(() {
                        invoiceItems.add({
                          'name': selectedProductName,
                          'price': price,
                          'quantity': qty,
                          'discount': 0.0,
                        });
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('إضافة', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
        title: const Text('فاتورة مبيعات جديدة', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // كارت إعدادات الفاتورة الأساسية
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // نوع الفاتورة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نوع الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'مبيعات', label: Text('مبيعات')),
                            ButtonSegment(value: 'مشتريات', label: Text('مشتريات')),
                          ],
                          selected: {invoiceType},
                          onSelectionChanged: (val) => setState(() => invoiceType = val.first),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // طريقة الدفع
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'نقدي', label: Text('نقدي')),
                            ButtonSegment(value: 'آجل (دين)', label: Text('آجل (دين)')),
                          ],
                          selected: {paymentType},
                          onSelectionChanged: (val) => setState(() => paymentType = val.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // اسم العميل
                    TextField(
                      controller: customerController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'اسم العميل',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0277BD)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // نوع التعامل
                    DropdownButtonFormField<String>(
                      value: dealingType,
                      decoration: InputDecoration(
                        labelText: 'نوع التعامل',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'مفرق', child: Text('مفرق')),
                        DropdownMenuItem(value: 'جملة', child: Text('جملة')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => dealingType = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // سعر الصرف
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('سعر الصرف:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$ 1 = ${exchangeRateController.text} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // زر إضافة منتج للفاتورة
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  side: const BorderSide(color: Color(0xFF0277BD)),
                ),
                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0277BD)),
                label: const Text(
                  'إضافة منتج للفاتورة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0277BD)),
                ),
                onPressed: _showAddProductDialog,
              ),
            ),
            const SizedBox(height: 12),

            // قائمة المواد المضافة داخل الفاتورة
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoiceItems.length,
              itemBuilder: (context, index) {
                final item = invoiceItems[index];
                final double totalItemPrice = (item['price'] as double) * (item['quantity'] as int) - (item['discount'] as double);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  invoiceItems.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الكمية: ${item['quantity']} × ${item['price']} ل.س ($dealingType)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('$totalItemPrice ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('حسم مباشر: ', style: TextStyle(fontSize: 12, color: Colors.red)),
                            SizedBox(
                              width: 80,
                              height: 30,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(),
                                  suffixText: 'ل.س',
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    item['discount'] = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 30),

            // المجاميع النهائية والحسم الإجمالي
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الفرعي:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${subTotal.toStringAsFixed(1)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('حسم الفاتورة الإجمالي:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: 100,
                          height: 35,
                          child: TextField(
                            controller: globalDiscountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(),
                              suffixText: 'ل.س',
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الفاتورة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${grandTotal.toStringAsFixed(1)} ل.س', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // زر حفظ الفاتورة
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0277BD)),
                onPressed: invoiceItems.isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
                        );
                        Navigator.pop(context);
                      },
                child: const Text('حفظ الفاتورة', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
