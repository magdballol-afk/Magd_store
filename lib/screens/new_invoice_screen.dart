import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({super.key, this.existingInvoice});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String _paymentType = 'آجل (دين)';
  String _dealType = 'مفرق';
  String _currency = 'ليرة سورية';

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  final List<Map<String, dynamic>> _customersList = [
    {'name': 'محمد أحمد العلي', 'phone': '0911111111', 'previousBalance': 15000.0},
    {'name': 'محمود سليمان', 'phone': '0922222222', 'previousBalance': 0.0},
    {'name': 'أحمد إبراهيم', 'phone': '0933333333', 'previousBalance': 45000.0},
    {'name': 'خالد السعيد', 'phone': '0944444444', 'previousBalance': 12000.0},
    {'name': 'سامر خليل', 'phone': '0955555555', 'previousBalance': 0.0},
  ];

  final List<Map<String, dynamic>> _productsList = [
    {
      'name': 'شامبو بانتين 400 مل',
      'barcode': '101',
      'priceRetail': 12500.0,
      'priceHalfWholesale': 11500.0,
      'priceWholesale': 10500.0,
    },
    {
      'name': 'صابون دوف 100 غرام',
      'barcode': '102',
      'priceRetail': 4500.0,
      'priceHalfWholesale': 4000.0,
      'priceWholesale': 3750.0,
    },
    {
      'name': 'معجون أسنان كولجيت',
      'barcode': '103',
      'priceRetail': 8000.0,
      'priceHalfWholesale': 7500.0,
      'priceWholesale': 7000.0,
    },
    {
      'name': 'مسحوق غسيل أرييل 1 كغ',
      'barcode': '104',
      'priceRetail': 22000.0,
      'priceHalfWholesale': 20500.0,
      'priceWholesale': 19500.0,
    },
  ];

  final List<Map<String, dynamic>> _invoiceItems = [];

  double _previousBalance = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _customerNameController.text = inv['customerName'] ?? '';
      _paymentType = inv['paymentType'] ?? 'آجل (دين)';
      _dealType = inv['dealType'] ?? 'مفرق';
      _currency = inv['currency'] ?? 'ليرة سورية';
    }
  }

  double get _subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  double get _netTotal => _subtotal;

  double get _paidAmount {
    if (_paymentType == 'نقدي') {
      return _netTotal;
    }
    return double.tryParse(_paidAmountController.text) ?? 0.0;
  }

  double get _remainingBalance {
    if (_paymentType == 'نقدي') {
      return 0.0;
    }
    return (_netTotal + _previousBalance) - _paidAmount;
  }

  void _resetForm() {
    setState(() {
      _paymentType = 'آجل (دين)';
      _dealType = 'مفرق';
      _currency = 'ليرة سورية';
      _customerNameController.clear();
      _paidAmountController.clear();
      _previousBalance = 0.0;
      _invoiceItems.clear();
    });
  }

  void _saveInvoice() {
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إضافة منتج واحد على الأقل للفاتورة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paymentType == 'آجل (دين)' && _customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال/اختيار اسم العميل لتسجيل الفاتورة الآجلة!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الفاتورة بنجاح'),
        backgroundColor: Colors.green,
      ),
    );

    _resetForm();
  }

  void _showAddProductDialog() {
    final TextEditingController productNameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');

    final currencySymbol = _currency == 'ليرة سورية' ? 'ل.س' : '\$';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'إضافة مادة للفاتورة',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('اسم المادة أو الباركود:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return RawAutocomplete<Map<String, dynamic>>(
                          textEditingController: productNameController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const [];
                            }
                            return _productsList.where((prod) {
                              final name = prod['name'].toString().toLowerCase();
                              final barcode = prod['barcode'].toString();
                              final query = textEditingValue.text.toLowerCase();
                              return name.contains(query) || barcode.contains(query);
                            });
                          },
                          displayStringForOption: (option) => option['name'],
                          onSelected: (option) {
                            double basePrice = option['priceRetail'];
                            if (_dealType == 'جملة') {
                              basePrice = option['priceWholesale'];
                            } else if (_dealType == 'نصف جملة') {
                              basePrice = option['priceHalfWholesale'];
                            }
                            priceController.text = basePrice.toString();
                            setDialogState(() {});
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'ابحث عن مادة...',
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF0277BD)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  width: constraints.maxWidth,
                                  color: Colors.white,
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(
                                          option['name'],
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          'باركود: ${option['barcode']}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('الكمية:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('السعر ($currencySymbol):', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: 'السعر',
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0277BD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final String name = productNameController.text.trim();
                    final double? price = double.tryParse(priceController.text);
                    final int? qty = int.tryParse(quantityController.text);

                    if (name.isEmpty || price == null || qty == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى التحقق من صحة البيانات المدخلة'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _invoiceItems.add({
                        'name': name,
                        'quantity': qty,
                        'price': price,
                        'total': price * qty,
                      });
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildToggleOption<T>({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0277BD) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _currency == 'ليرة سورية' ? 'ل.س' : '\$';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'فاتورة جديدة',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                _buildToggleOption(
                  label: 'آجل (دين)',
                  isSelected: _paymentType == 'آجل (دين)',
                  onTap: () => setState(() => _paymentType = 'آجل (دين)'),
                ),
                const SizedBox(width: 8),
                _buildToggleOption(
                  label: 'نقدي',
                  isSelected: _paymentType == 'نقدي',
                  onTap: () {
                    setState(() {
                      _paymentType = 'نقدي';
                      _paidAmountController.clear();
                    });
                  },
                ),
                const SizedBox(width: 12),
                const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildToggleOption(
                  label: 'جملة',
                  isSelected: _dealType == 'جملة',
                  onTap: () => setState(() => _dealType = 'جملة'),
                ),
                const SizedBox(width: 6),
                _buildToggleOption(
                  label: 'نصف جملة',
                  isSelected: _dealType == 'نصف جملة',
                  onTap: () => setState(() => _dealType = 'نصف جملة'),
                ),
                const SizedBox(width: 6),
                _buildToggleOption(
                  label: 'مفرق',
                  isSelected: _dealType == 'مفرق',
                  onTap: () => setState(() => _dealType = 'مفرق'),
                ),
                const SizedBox(width: 12),
                const Text('نوع التعامل:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildToggleOption(
                  label: 'دولار (\$)',
                  isSelected: _currency == 'دولار (\$)',
                  onTap: () => setState(() => _currency = 'دولار (\$)'),
                ),
                const SizedBox(width: 8),
                _buildToggleOption(
                  label: 'ليرة سورية',
                  isSelected: _currency == 'ليرة سورية',
                  onTap: () => setState(() => _currency = 'ليرة سورية'),
                ),
                const SizedBox(width: 12),
                const Text('عملة الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            RawAutocomplete<Map<String, dynamic>>(
              textEditingController: _customerNameController,
              focusNode: FocusNode(),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const [];
                }
                return _customersList.where((customer) {
                  final name = customer['name'].toString().toLowerCase();
                  final phone = customer['phone'].toString();
                  final query = textEditingValue.text.toLowerCase();
                  return name.contains(query) || phone.contains(query);
                });
              },
              displayStringForOption: (Map<String, dynamic> option) => option['name'],
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  _customerNameController.text = selection['name'];
                  _previousBalance = (selection['previousBalance'] as double);
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث أو أدخل اسم العميل...',
                    prefixIcon: const Icon(Icons.person_search, color: Color(0xFF0277BD)),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _previousBalance = 0.0;
                              });
                            },
                          )
                        : null,
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      width: MediaQuery.of(context).size.width - 32,
                      color: Colors.white,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(
                              option['name'],
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'الهاتف: ${option['phone']} | رصيد سابق: ${option['previousBalance']} $currencySymbol',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  side: const BorderSide(color: Color(0xFF0277BD)),
                ),
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0277BD)),
                label: Text(
                  'إضافة منتج للفاتورة ($_dealType)',
                  style: const TextStyle(color: Color(0xFF0277BD), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              ':المنتجات المضافة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            if (_invoiceItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('لم يتم إضافة أي منتج بعد', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._invoiceItems.asMap().entries.map((entry) {
                int index = entry.key;
                var item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _invoiceItems.removeAt(index);
                          });
                        },
                      ),
                      Text('${item['total']} $currencySymbol',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${item['quantity']} × ${item['price']} $currencySymbol',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_subtotal $currencySymbol', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text(':المجموع الفرعي', style: TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_netTotal $currencySymbol',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                const Text(':صافي الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_previousBalance $currencySymbol', style: const TextStyle(color: Colors.grey)),
                const Text(':رصيد سابق مترتب', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            if (_paymentType == 'آجل (دين)') ...[
              TextField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'الدفعة المقبوضة ($currencySymbol)',
                  prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_remainingBalance $currencySymbol',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _remainingBalance > 0 ? Colors.red : Colors.green,
                  ),
                ),
                const Text(':الرصيد الحالي المتبقي', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0277BD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _saveInvoice,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'حفظ الفاتورة',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
