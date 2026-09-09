import 'package:flutter/material.dart';

// نموذج يمثل عنصر الفاتورة
class InvoiceItem {
  final String name;
  final double price;
  final int quantity;
  final double discount; // حسم المادة

  InvoiceItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.discount = 0.0,
  });

  double get total => (price * quantity) - discount;
}

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // خيارات الفاتورة
  String paymentType = 'آجل (دين)';
  String dealType = 'مفرق';
  String currency = 'ليرة سورية';

  // القوائم والمُدخلات
  final List<InvoiceItem> _addedProducts = [];
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _totalDiscountController = TextEditingController(); // حسم الفاتورة الكلي

  double previousBalance = 0.0; // رصيد سابق مترتب

  // حساب المجموع الفرعي (مجموع العناصر قبل الحسم الكلي)
  double get subTotal {
    return _addedProducts.fold(0.0, (sum, item) => sum + item.total);
  }

  // حساب الخصم الكلي للفاتورة
  double get totalDiscount {
    return double.tryParse(_totalDiscountController.text) ?? 0.0;
  }

  // حساب صافي الفاتورة
  double get netTotal {
    double total = subTotal - totalDiscount;
    return total < 0 ? 0 : total;
  }

  // حساب الرصيد المتبقي
  double get remainingBalance {
    double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return (netTotal + previousBalance) - paid;
  }

  @override
  void dispose() {
    _customerController.dispose();
    _paidAmountController.dispose();
    _totalDiscountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'فاتورة جديدة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // طريقة الدفع
              _buildToggleSection(
                title: ':طريقة الدفع',
                options: ['آجل (دين)', 'نقدي'],
                selectedValue: paymentType,
                onSelect: (val) => setState(() => paymentType = val),
              ),
              const SizedBox(height: 12),

              // نوع التعامل
              _buildToggleSection(
                title: ':نوع التعامل',
                options: ['مفرق', 'نصف جملة', 'جملة'],
                selectedValue: dealType,
                onSelect: (val) => setState(() => dealType = val),
              ),
              const SizedBox(height: 12),

              // عملة الفاتورة
              _buildToggleSection(
                title: ':عملة الفاتورة',
                options: ['ليرة سورية', '($) دولار'],
                selectedValue: currency,
                onSelect: (val) => setState(() => currency = val),
              ),
              const SizedBox(height: 16),

              // البحث/إدخال العميل
              TextField(
                controller: _customerController,
                decoration: _inputDecoration(
                  hintText: '...ابحث أو أدخل اسم العميل',
                  prefixIcon: Icons.person_search_outlined,
                ),
              ),
              const SizedBox(height: 12),

              // زر إضافة منتج
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0D47A1)),
                label: Text(
                  'إضافة منتج للفاتورة ($dealType)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
              ),
              const SizedBox(height: 16),

              // قائمة المنتجات المضافة
              const Text('المنتجات المضافة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),

              _addedProducts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('لم يتم إضافة أي منتج بعد', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _addedProducts.length,
                      itemBuilder: (context, index) {
                        final item = _addedProducts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('الكمية: ${item.quantity} | السعر: ${item.price} | حسم: ${item.discount}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${item.total} $currency', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _addedProducts.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              const Divider(height: 32),

              // المجموع الفرعي
              _buildSummaryRow('المجموع الفرعي:', '${subTotal.toStringAsFixed(1)} $currency'),
              const SizedBox(height: 8),

              // حقل حسم كلي للفاتورة (إضافة جديدة)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('حسم الفاتورة الكلي:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  SizedBox(
                    width: 140,
                    height: 40,
                    child: TextField(
                      controller: _totalDiscountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0.0',
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // صافي الفاتورة
              _buildSummaryRow(
                'صافي الفاتورة:',
                '${netTotal.toStringAsFixed(1)} $currency',
                valueColor: Colors.green.shade700,
                isBold: true,
              ),
              const SizedBox(height: 6),

              _buildSummaryRow('رصيد سابق مترتب:', '${previousBalance.toStringAsFixed(1)} $currency', valueColor: Colors.grey),
              const SizedBox(height: 12),

              // الدفعة المقبوضة
              TextField(
                controller: _paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => setState(() {}),
                decoration: _inputDecoration(
                  hintText: 'الدفعة المقبوضة ($currency)',
                  prefixIcon: Icons.money_outlined,
                ),
              ),
              const SizedBox(height: 12),

              // الرصيد الحالي المتبقي
              _buildSummaryRow(
                'الرصيد الحالي المتبقي:',
                '${remainingBalance.toStringAsFixed(1)} $currency',
                valueColor: Colors.green.shade700,
                isBold: true,
              ),
              const SizedBox(height: 24),

              // زر حفظ الفاتورة
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveInvoice,
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // نافذة إضافة مادة مع حسم اختياري لكل مادة
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final itemDiscountController = TextEditingController(text: '0'); // حسم اختياري للمادة

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Center(child: Text('إضافة مادة للفاتورة', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم المادة أو الباركود', prefixIcon: Icon(Icons.search)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'السعر'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الكمية'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: itemDiscountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'الحسم على المادة (اختياري)',
                  prefixIcon: Icon(Icons.discount_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final price = double.tryParse(priceController.text) ?? 0.0;
                  final qty = int.tryParse(quantityController.text) ?? 1;
                  final discount = double.tryParse(itemDiscountController.text) ?? 0.0;

                  setState(() {
                    _addedProducts.add(InvoiceItem(
                      name: nameController.text,
                      price: price,
                      quantity: qty,
                      discount: discount,
                    ));
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSection({
    required String title,
    required List<String> options,
    required String selectedValue,
    required Function(String) onSelect,
  }) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                selectedColor: const Color(0xFF0D47A1),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                onSelected: (_) => onSelect(option),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF0D47A1)),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  void _saveInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
    );
  }
}
