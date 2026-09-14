import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({Key? key, this.existingInvoice}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String _currency = 'ليرة سورية';
  String _discountType = 'مبلغ'; // 'مبلغ' أو '%'
  String _dealType = 'مفرق'; // 'مفرق' / 'نصف جملة' / 'جملة'

  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.0');
  final TextEditingController _paidController = TextEditingController(text: '0.0');

  // متحكمات حقل البحث المتقدم وإضافة المنتج
  final TextEditingController _searchProductController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _itemQtyController = TextEditingController(text: '1');
  
  Map<String, dynamic>? _selectedProductFromSearch;
  List<Map<String, dynamic>> _allProducts = [];

  List<Map<String, dynamic>> _invoiceItems = [];

  double _subtotal = 0.0;
  double _discountAmount = 0.0;
  double _netTotal = 0.0;
  double _previousBalance = 0.0;
  double _remainingBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();

    if (widget.existingInvoice != null) {
      _clientController.text = widget.existingInvoice!['client_name'] ?? '';
      _currency = widget.existingInvoice!['currency'] ?? 'ليرة سورية';
      _dealType = widget.existingInvoice!['deal_type'] ?? 'مفرق';
    }
    _discountController.addListener(_calculateTotals);
    _paidController.addListener(_calculateTotals);
  }

  Future<void> _loadProducts() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _allProducts = products;
    });
  }

  // تحديث سعر المنتج المحدد حالياً في حقل البحث وفقاً لنوع التعامل
  void _updateSelectedProductPrice() {
    if (_selectedProductFromSearch != null) {
      double defaultPrice = (_selectedProductFromSearch!['price_retail'] as num?)?.toDouble() ?? 0.0;
      if (_dealType == 'نصف جملة') {
        defaultPrice = (_selectedProductFromSearch!['price_half_wholesale'] as num?)?.toDouble() ?? defaultPrice;
      } else if (_dealType == 'جملة') {
        defaultPrice = (_selectedProductFromSearch!['price_wholesale'] as num?)?.toDouble() ?? defaultPrice;
      }
      _itemPriceController.text = defaultPrice.toString();
    }
  }

  void _calculateTotals() {
    double sum = 0.0;
    for (var item in _invoiceItems) {
      sum += (item['total'] as double);
    }
    _subtotal = sum;

    double discInput = double.tryParse(_discountController.text) ?? 0.0;
    if (_discountType == '%') {
      _discountAmount = (_subtotal * discInput) / 100;
    } else {
      _discountAmount = discInput;
    }

    _netTotal = _subtotal - _discountAmount;
    if (_netTotal < 0) _netTotal = 0;

    double paid = double.tryParse(_paidController.text) ?? 0.0;
    _remainingBalance = (_netTotal + _previousBalance) - paid;

    setState(() {});
  }

  void _addItemToInvoice() {
    final String productName = _selectedProductFromSearch != null
        ? _selectedProductFromSearch!['name']
        : _searchProductController.text.trim();

    final double price = double.tryParse(_itemPriceController.text) ?? 0.0;
    final double qty = double.tryParse(_itemQtyController.text) ?? 1.0;

    if (productName.isNotEmpty && price > 0 && qty > 0) {
      setState(() {
        _invoiceItems.add({
          'product_id': _selectedProductFromSearch?['id'],
          'product_name': productName,
          'price': price,
          'quantity': qty,
          'total': price * qty,
        });
        _calculateTotals();

        // إعادة ضبط حقول البحث والإضافة
        _selectedProductFromSearch = null;
        _searchProductController.clear();
        _itemPriceController.clear();
        _itemQtyController.text = '1';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى التأكد من اختيار المنتج وتحديد السعر والكمية بشكل صحيح'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0052CC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. عملة الفاتورة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'عملة الفاتورة:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    _buildCurrencyChip('دولار (\$)'),
                    const SizedBox(width: 8),
                    _buildCurrencyChip('ليرة سورية'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. نوع التعامل (مفرق / نصف جملة / جملة)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'نوع التعامل:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      _buildDealTypeBtn('جملة'),
                      _buildDealTypeBtn('نصف جملة'),
                      _buildDealTypeBtn('مفرق'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. إدخال اسم العميل
            TextField(
              controller: _clientController,
              decoration: InputDecoration(
                hintText: '...ابحث أو أدخل اسم العميل',
                prefixIcon: const Icon(Icons.person_search_outlined),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. حقل البحث المتقدم وإضافة المنتج المباشر
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0052CC).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إضافة منتج للفاتورة ($_dealType):',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
                      ),
                      const Icon(Icons.saved_search, color: Color(0xFF0052CC)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // حقل البحث المتقدم
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<Map<String, dynamic>>(
                        displayStringForOption: (option) => option['name'] as String,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }
                          return _allProducts.where((product) {
                            final name = (product['name'] as String).toLowerCase();
                            final barcode = (product['barcode'] as String?)?.toLowerCase() ?? '';
                            final query = textEditingValue.text.toLowerCase();
                            return name.contains(query) || barcode.contains(query);
                          });
                        },
                        onSelected: (Map<String, dynamic> selection) {
                          _selectedProductFromSearch = selection;
                          _searchProductController.text = selection['name'];
                          _updateSelectedProductPrice();
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (text) {
                              _searchProductController.text = text;
                            },
                            decoration: InputDecoration(
                              hintText: 'ابحث باسم المنتج أو الباركود...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF0052CC)),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FE),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
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
                              elevation: 6.0,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: constraints.maxWidth,
                                constraints: const BoxConstraints(maxHeight: 200), // تم تصحيح الخاصية هنا
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (BuildContext context, int index) {
                                    final option = options.elementAt(index);
                                    
                                    // عرض السعر المناسب في القائمة المنسدلة وفق نوع التعامل
                                    double displayPrice = (option['price_retail'] as num?)?.toDouble() ?? 0.0;
                                    if (_dealType == 'نصف جملة') {
                                      displayPrice = (option['price_half_wholesale'] as num?)?.toDouble() ?? displayPrice;
                                    } else if (_dealType == 'جملة') {
                                      displayPrice = (option['price_wholesale'] as num?)?.toDouble() ?? displayPrice;
                                    }

                                    return ListTile(
                                      title: Text(
                                        option['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        'المخزون: ${option['quantity']} | السعر ($_dealType): $displayPrice $_currency',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF0052CC)),
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

                  // السعر والكمية وسريعة الإضافة
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _itemPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'السعر',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _itemQtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'الكمية',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052CC),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _addItemToInvoice,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. المنتجات المضافة
            const Text(
              ':المنتجات المضافة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _invoiceItems.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'لم يتم إضافة أي منتج بعد',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _invoiceItems.length,
                    itemBuilder: (context, index) {
                      final item = _invoiceItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('الكمية: ${item['quantity']} × ${item['price']} $_currency'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item['total']} $_currency',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _invoiceItems.removeAt(index);
                                    _calculateTotals();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const Divider(height: 32, thickness: 1),

            // 6. المجموع الفرعي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المجموع الفرعي:', style: TextStyle(fontSize: 15, color: Colors.grey)),
                Text(
                  '$_subtotal $_currency',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7. حسم الفاتورة الكلي (مبلغ / %)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('حسم الفاتورة الكلي:', style: TextStyle(fontSize: 15, color: Colors.grey)),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildDiscountTypeBtn('%'),
                          _buildDiscountTypeBtn('مبلغ'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      height: 42,
                      child: TextField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 8. صافي الفاتورة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('صافي الفاتورة:', style: TextStyle(fontSize: 15, color: Colors.grey)),
                Text(
                  '$_netTotal $_currency',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 9. رصيد سابق مترتب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('رصيد سابق مترتب:', style: TextStyle(fontSize: 15, color: Colors.grey)),
                Text(
                  '$_previousBalance $_currency',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 10. الدفعة المقبوضة
            TextField(
              controller: _paidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'الدفعة المقبوضة ($_currency)',
                prefixIcon: const Icon(Icons.payments_outlined),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // 11. الرصيد الحالي المتبقي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الرصيد الحالي المتبقي:', style: TextStyle(fontSize: 15, color: Colors.grey)),
                Text(
                  '$_remainingBalance $_currency',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 12. أزرار حفظ الفاتورة والطباعة
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save_outlined, color: Colors.white),
                      label: const Text(
                        'حفظ الفاتورة',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A884),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      onPressed: () {
                        // إجراءات الطباعة
                      },
                      icon: const Icon(Icons.print_outlined, color: Colors.white),
                      label: const Text(
                        'طباعة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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

  Widget _buildCurrencyChip(String label) {
    final isSelected = _currency == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF0052CC),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _currency = label;
            _calculateTotals();
          });
        }
      },
    );
  }

  Widget _buildDealTypeBtn(String type) {
    final isSelected = _dealType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _dealType = type;
          _updateSelectedProductPrice();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052CC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountTypeBtn(String type) {
    final isSelected = _discountType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _discountType = type;
          _calculateTotals();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052CC).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0052CC) : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
