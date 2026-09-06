import 'package:flutter/material.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  String _invoiceType = 'مبيعات'; // مبيعات أو مشتريات
  String _paymentType = 'نقدي'; // نقدي أو أجل (دين)
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _overallDiscountController = TextEditingController(text: '0');

  // قائمة المواد المضافة للفاتورة
  List<Map<String, dynamic>> _selectedProducts = [
    {'name': 'ميموزا', 'qty': 1, 'price': 1000.0, 'discount': 0.0},
    {'name': 'ديمة', 'qty': 1, 'price': 1000.0, 'discount': 0.0},
  ];

  // حساب المجموع الكلي
  double get _subtotal {
    double total = 0;
    for (var item in _selectedProducts) {
      double itemTotal = (item['qty'] * item['price']) - item['discount'];
      total += itemTotal > 0 ? itemTotal : 0;
    }
    return total;
  }

  double get _overallDiscount => double.tryParse(_overallDiscountController.text) ?? 0.0;

  double get _finalTotal {
    double net = _subtotal - _overallDiscount;
    return net > 0 ? net : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_invoiceType == 'مبيعات' ? 'فاتورة مبيعات جديدة' : 'فاتورة مشتريات جديدة'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // قسم نوع الفاتورة وطريقة الدفع
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('نوع الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ToggleButtons(
                            isSelected: [_invoiceType == 'مبيعات', _invoiceType == 'مشتريات'],
                            onPressed: (index) {
                              setState(() {
                                _invoiceType = index == 0 ? 'مبيعات' : 'مشتريات';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            children: const [
                              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('مبيعات')),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('مشتريات')),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ToggleButtons(
                            isSelected: [_paymentType == 'نقدي', _paymentType == 'آجل (دين)'],
                            onPressed: (index) {
                              setState(() {
                                _paymentType = index == 0 ? 'نقدي' : 'آجل (دين)';
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            children: const [
                              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('نقدي')),
                              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('آجل (دين)')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _clientController,
                        decoration: InputDecoration(
                          labelText: _invoiceType == 'مبيعات' ? 'اسم العميل' : 'اسم المورد',
                          prefixIcon: const Icon(Icons.person),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // سعر الصرف
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('سعر الصرف:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('1 \$ = 15000 ل.س', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // زر إضافة منتج
              OutlinedButton.icon(
                onPressed: () {
                  // فتح نافذة اختيار مادة
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('إضافة منتج للفاتورة'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 12),

              // قائمة المواد مع الحسم المباشر لكل مادة
              ..._selectedProducts.map((item) {
                double totalItemPrice = (item['qty'] * item['price']) - item['discount'];
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
                            Text('${totalItemPrice.toStringAsFixed(1)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('الكمية: ${item['qty']} × ${item['price']} ل.س', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        
                        // حقل حسم شريحة مباشر للمادة (يظهر دائماً أو عند المشتريات)
                        Row(
                          children: [
                            const Text('حسم مباشر:', style: TextStyle(fontSize: 12, color: Colors.red)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              height: 30,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  border: OutlineInputBorder(),
                                  hintText: '0.0',
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    item['discount'] = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                            const Text(' ل.س', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const Divider(height: 24),

              // قسم الحسم الإجمالي والمجموع النهائي
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المجموع الفرعي:'),
                          Text('${_subtotal.toStringAsFixed(0)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // حسم إجمالي على الفاتورة ككل (خصيصاً لـ المشتريات والمبيعات)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('حسم الفاتورة الإجمالي:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 120,
                            height: 35,
                            child: TextField(
                              controller: _overallDiscountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                border: OutlineInputBorder(),
                                suffixText: 'ل.س',
                              ),
                              onChanged: (val) {
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي النهائي (SYP):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                          Text('${_finalTotal.toStringAsFixed(0)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي (USD):', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          Text('\$ ${(_finalTotal / 15000).toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    // حفظ الفاتورة
                  },
                  child: const Text('حفظ وإصدار الفاتورة', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
