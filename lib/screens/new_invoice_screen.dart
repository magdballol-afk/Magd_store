import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({super.key, this.existingInvoice});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // خيارات الفاتورة
  bool _isSales = true; // true: مبيعات, false: مشتريات
  bool _isCash = true; // true: نقدي, false: أجل (دين)
  String _currency = 'ليرة سورية (ل.س)';
  
  // نوع التعامل (تحديد فئة السعر)
  String _dealType = 'مفرق'; // الخيارات: مفرق، نصف جملة، جملة

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  // قائمة المنتجات المضافة للفاتورة الحالية
  List<Map<String, dynamic>> _selectedInvoiceItems = [];

  // قائمة المنتجات الكلية في المحل مع أسعار الفئات المحددة
  final List<Map<String, dynamic>> _allProducts = [
    {
      'name': 'بسكويت سادة',
      'priceRetail': 2000.0,        // مفرق
      'priceHalfWholesale': 1800.0,   // نصف جملة
      'priceWholesale': 1500.0,     // جملة
    },
    {
      'name': 'بسكويت محشي',
      'priceRetail': 3500.0,
      'priceHalfWholesale': 3200.0,
      'priceWholesale': 2800.0,
    },
    {
      'name': 'شيبس بالملح',
      'priceRetail': 5000.0,
      'priceHalfWholesale': 4500.0,
      'priceWholesale': 4000.0,
    },
  ];

  double _previousBalance = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _isSales = inv['isSales'] ?? true;
      _isCash = inv['isCash'] ?? true;
      _dealType = inv['dealType'] ?? 'مفرق';
      _customerController.text = inv['customerName'] ?? '';
      _paidAmountController.text = (inv['paidAmount'] ?? 0.0).toString();
      if (inv['items'] != null) {
        _selectedInvoiceItems = List<Map<String, dynamic>>.from(inv['items']);
      }
    }
  }

  // تحديد سعر المنتج بناءً على نوع التعامل المختار
  double _getProductPrice(Map<String, dynamic> product) {
    if (_dealType == 'جملة') {
      return product['priceWholesale'] ?? 0.0;
    } else if (_dealType == 'نصف جملة') {
      return product['priceHalfWholesale'] ?? 0.0;
    } else {
      return product['priceRetail'] ?? 0.0; // مفرق
    }
  }

  double get _subtotal => _selectedInvoiceItems.fold(
      0.0, (sum, item) => sum + ((item['price'] as double) * (item['quantity'] as int)));

  double get _netTotal => _subtotal;

  double get _remainingBalance {
    double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return (_netTotal + _previousBalance) - paid;
  }

  // نافذة البحث والانتفاء الذكي للمواد
  void _showAddProductDialog() {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredProducts = _allProducts.where((product) {
              final name = product['name'].toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'بحث وإضافة منتج (السعر: $_dealType)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // حقل البحث المباشر
                  TextField(
                    autofocus: true,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'اكتب اسم المنتج (مثال: بسك)...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0277BD)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // قائمة النتائج المفلترة
                  SizedBox(
                    height: 250,
                    child: filteredProducts.isEmpty
                        ? const Center(
                            child: Text(
                              'لا يوجد منتج يطابق بحثك',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final prod = filteredProducts[index];
                              final price = _getProductPrice(prod);
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    prod['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'السعر ($_dealType): $price ${_currency == 'ليرة سورية (ل.س)' ? 'ل.س' : '\$'}',
                                  ),
                                  trailing: const Icon(Icons.add_shopping_cart, color: Color(0xFF0277BD)),
                                  onTap: () {
                                    setState(() {
                                      int existingIndex = _selectedInvoiceItems.indexWhere(
                                        (e) => e['name'] == prod['name'],
                                      );
                                      if (existingIndex != -1) {
                                        _selectedInvoiceItems[existingIndex]['quantity'] += 1;
                                      } else {
                                        _selectedInvoiceItems.add({
                                          'name': prod['name'],
                                          'price': price,
                                          'quantity': 1,
                                        });
                                      }
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currSymbol = _currency == 'ليرة سورية (ل.س)' ? 'ل.س' : '\$';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
        title: Text(
          widget.existingInvoice == null ? 'فاتورة جديدة' : 'تعديل فاتورة',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // نوع الفاتورة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نوع الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ToggleButtons(
                          isSelected: [_isSales, !_isSales],
                          borderRadius: BorderRadius.circular(20),
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF0277BD),
                          constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
                          onPressed: (index) {
                            setState(() {
                              _isSales = index == 0;
                            });
                          },
                          children: const [
                            Text('مبيعات'),
                            Text('مشتريات'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // طريقة الدفع
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ToggleButtons(
                          isSelected: [_isCash, !_isCash],
                          borderRadius: BorderRadius.circular(20),
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF0277BD),
                          constraints: const BoxConstraints(minWidth: 80, minHeight: 36),
                          onPressed: (index) {
                            setState(() {
                              _isCash = index == 0;
                            });
                          },
                          children: const [
                            Text('نقدي'),
                            Text('آجل (دين)'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // نوع التعامل (مفرق - نصف جملة - جملة)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نوع التعامل:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ToggleButtons(
                          isSelected: [
                            _dealType == 'مفرق',
                            _dealType == 'نصف جملة',
                            _dealType == 'جملة',
                          ],
                          borderRadius: BorderRadius.circular(20),
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF0277BD),
                          constraints: const BoxConstraints(minWidth: 65, minHeight: 36),
                          onPressed: (index) {
                            setState(() {
                              if (index == 0) _dealType = 'مفرق';
                              if (index == 1) _dealType = 'نصف جملة';
                              if (index == 2) _dealType = 'جملة';
                            });
                          },
                          children: const [
                            Text('مفرق', style: TextStyle(fontSize: 12)),
                            Text('نصف جملة', style: TextStyle(fontSize: 11)),
                            Text('جملة', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // عملة الفاتورة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('عملة الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ToggleButtons(
                          isSelected: [_currency == 'ليرة سورية (ل.س)', _currency == 'دولار (\$)'],
                          borderRadius: BorderRadius.circular(20),
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF0277BD),
                          constraints: const BoxConstraints(minWidth: 90, minHeight: 36),
                          onPressed: (index) {
                            setState(() {
                              _currency = index == 0 ? 'ليرة سورية (ل.س)' : 'دولار (\$)';
                            });
                          },
                          children: const [
                            Text('ليرة سورية'),
                            Text('دولار (\$)'),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // اسم العميل
                    TextField(
                      controller: _customerController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'اسم العميل',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0277BD)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // زر إضافة منتج للفاتورة
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Color(0xFF0277BD), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0277BD)),
              label: Text(
                'إضافة منتج للفاتورة ($_dealType)',
                style: const TextStyle(color: Color(0xFF0277BD), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _showAddProductDialog,
            ),
            const SizedBox(height: 12),

            if (_selectedInvoiceItems.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedInvoiceItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _selectedInvoiceItems[index];
                    return ListTile(
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الكمية: ${item['quantity']} × ${item['price']} $currSymbol'),
                      trailing: Text(
                        '${item['quantity'] * item['price']} $currSymbol',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الفرعي:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_subtotal.toStringAsFixed(1)} $currSymbol', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${_netTotal.toStringAsFixed(1)} $currSymbol',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, size: 18, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('رصيد سابق مترتب:', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Text('${_previousBalance.toStringAsFixed(1)} $currSymbol', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _paidAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'الدفعة المقبوضة ($currSymbol)',
                        prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الرصيد الحالي المتبقي:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${_remainingBalance.toStringAsFixed(1)} $currSymbol',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _remainingBalance > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0277BD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
                  );
                },
                child: const Text('حفظ الفاتورة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
