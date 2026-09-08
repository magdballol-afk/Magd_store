import 'package:flutter/material.dart';

// 1. نموذج بيانات المنتج
class Product {
  final String id;
  final String name;
  final double retailPrice; // سعر المفرق
  final double semiWholesalePrice; // سعر نصف الجملة
  final double wholesalePrice; // سعر الجملة

  Product({
    required this.id,
    required this.name,
    required this.retailPrice,
    required this.semiWholesalePrice,
    required this.wholesalePrice,
  });

  // إرجاع السعر المناسب حسب نوع التعامل
  double getPriceByTradeType(String tradeType) {
    switch (tradeType) {
      case 'جملة':
        return wholesalePrice;
      case 'نصف جملة':
        return semiWholesalePrice;
      case 'مفرق':
      default:
        return retailPrice;
    }
  }
}

// 2. نموذج عنصر الفاتورة (المنتج + الكمية)
class InvoiceItem {
  final Product product;
  int quantity;
  final double price;

  InvoiceItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;
}

class NewInvoiceScreen extends StatefulWidget {
  final dynamic existingInvoice;

  const NewInvoiceScreen({
    Key? key,
    this.existingInvoice,
  }) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // الخيارات الأساسية
  String _invoiceType = 'مبيعات';
  String _paymentMethod = 'نقدي';
  String _tradeType = 'مفرق';
  String _currency = 'ليرة سورية';

  // المتحكمات
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  // قائمة العناصر المضافة للفاتورة
  final List<InvoiceItem> _selectedItems = [];
  double _previousBalance = 0.0;

  // قائمة منتجات تجريبية (يمكن استبدالها بقائمة قاعدة البيانات لديك)
  final List<Product> _availableProducts = [
    Product(id: '1', name: 'شامبو بانتين 400 مل', retailPrice: 12500, semiWholesalePrice: 11500, wholesalePrice: 10500),
    Product(id: '2', name: 'معجون أسنان كولجيت', retailPrice: 8000, semiWholesalePrice: 7500, wholesalePrice: 7000),
    Product(id: '3', name: 'صابون دوف 100 غ', retailPrice: 4500, semiWholesalePrice: 4000, wholesalePrice: 3800),
    Product(id: '4', name: 'مناديل فاين 500 منديل', retailPrice: 15000, semiWholesalePrice: 14000, wholesalePrice: 13000),
  ];

  @override
  void initState() {
    super.initState();
    _paidAmountController.addListener(_onPaidAmountChanged);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  // حساب المجموع الفرعي ديناميكياً بناءً على مجموع عناصر السلة
  double get _subTotal => _selectedItems.fold(0.0, (sum, item) => sum + item.total);

  double get _netTotal => _subTotal;

  double get _remainingBalance {
    double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return (_netTotal + _previousBalance) - paid;
  }

  void _updatePaymentLogic() {
    if (_paymentMethod == 'نقدي') {
      _paidAmountController.text = _netTotal.toStringAsFixed(2);
    }
  }

  void _onPaidAmountChanged() {
    setState(() {});
  }

  // فتح نافذة اختيار منتج مع بحث متقدم وتحديد الكمية
  void _openAddProductBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _AddProductModal(
          products: _availableProducts,
          tradeType: _tradeType,
          currencySymbol: _currencySymbol,
          onProductAdded: (product, quantity, price) {
            setState(() {
              // التحقق مما إذا كان المنتج مضافاً سابقاً للزيادة على كميته
              int existingIndex = _selectedItems.indexWhere((item) => item.product.id == product.id);
              if (existingIndex >= 0) {
                _selectedItems[existingIndex].quantity += quantity;
              } else {
                _selectedItems.add(InvoiceItem(
                  product: product,
                  quantity: quantity,
                  price: price,
                ));
              }
              _updatePaymentLogic();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingInvoice != null ? 'تعديل فاتورة' : 'فاتورة جديدة'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. خيارات الفاتورة
              _buildToggleRow(
                title: 'نوع الفاتورة:',
                options: ['مبيعات', 'مشتريات'],
                selectedValue: _invoiceType,
                onSelected: (val) => setState(() => _invoiceType = val),
              ),
              const SizedBox(height: 12),

              _buildToggleRow(
                title: 'طريقة الدفع:',
                options: ['نقدي', 'آجل (دين)'],
                selectedValue: _paymentMethod,
                onSelected: (val) {
                  setState(() {
                    _paymentMethod = val;
                    _updatePaymentLogic();
                  });
                },
              ),
              const SizedBox(height: 12),

              _buildToggleRow(
                title: 'نوع التعامل:',
                options: ['مفرق', 'نصف جملة', 'جملة'],
                selectedValue: _tradeType,
                onSelected: (val) {
                  setState(() {
                    _tradeType = val;
                    // إعادة تسعير العناصر المضافة وفق الفئة الجديدة
                    for (var item in _selectedItems) {
                      // تحديث السعر استناداً لنوع التعامل الجديد
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              _buildToggleRow(
                title: 'عملة الفاتورة:',
                options: ['ليرة سورية', r'دولار ($)'],
                selectedValue: _currency,
                onSelected: (val) => setState(() => _currency = val),
              ),
              const SizedBox(height: 16),

              // 2. اسم العميل
              TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: 'اسم العميل',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. زر إضافة منتج
              OutlinedButton.icon(
                onPressed: _openAddProductBottomSheet,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('إضافة منتج للفاتورة ($_tradeType)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. عرض قائمة المنتجات المضافة للفاتورة
              if (_selectedItems.isNotEmpty) ...[
                const Text(
                  'المنتجات المضافة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedItems.length,
                  itemBuilder: (context, index) {
                    final item = _selectedItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('${item.quantity} × ${item.price.toStringAsFixed(1)} $_currencySymbol'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.total.toStringAsFixed(1)} $_currencySymbol',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedItems.removeAt(index);
                                  _updatePaymentLogic();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 5. حسابات الفاتورة والمجاميع
              _buildSummaryRow('المجموع الفرعي:', _subTotal),
              const Divider(),
              _buildSummaryRow('صافي الفاتورة:', _netTotal, isHighlight: true),
              const SizedBox(height: 16),

              Text(
                'رصيد سابق مترتب: ${_previousBalance.toStringAsFixed(1)} $_currencySymbol',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // حقل الدفعة المقبوضة
              TextField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                enabled: _paymentMethod != 'نقدي',
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                  labelText: 'الدفعة المقبوضة ($_currencySymbol)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // الرصيد المتبقي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الرصيد الحالي المتبقي:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_remainingBalance.toStringAsFixed(1)} $_currencySymbol',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _remainingBalance > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _currencySymbol => _currency == 'ليرة سورية' ? 'ل.س' : r'$';

  Widget _buildToggleRow({
    required String title,
    required List<String> options,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: options.map((opt) {
                bool isSelected = opt == selectedValue;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelected(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        opt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(1)} $_currencySymbol',
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// 3. نافذة البحث المتقدم عن المنتج وتحديد الكمية (Modal BottomSheet)
class _AddProductModal extends StatefulWidget {
  final List<Product> products;
  final String tradeType;
  final String currencySymbol;
  final Function(Product product, int quantity, double price) onProductAdded;

  const _AddProductModal({
    Key? key,
    required this.products,
    required this.tradeType,
    required this.currencySymbol,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  State<_AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<_AddProductModal> {
  String _searchQuery = '';
  Product? _selectedProduct;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    List<Product> filteredProducts = widget.products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'بحث واختيار منتج',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // حقل البحث المتقدم
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم المنتج...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 12),

            // قائمة خيارات المواد المطابقة للبحث
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('لا توجد نتائج مطابقة'))
                  : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final price = product.getPriceByTradeType(widget.tradeType);
                        final isSelected = _selectedProduct?.id == product.id;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue.shade50,
                          title: Text(product.name),
                          subtitle: Text('السعر (${widget.tradeType}): $price ${widget.currencySymbol}'),
                          onTap: () {
                            setState(() {
                              _selectedProduct = product;
                            });
                          },
                        );
                      },
                    ),
            ),
            const Divider(),

            // التحكم بالكمية وإضافة المادة
            if (_selectedProduct != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الكمية المطلوب إضافتها:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final price = _selectedProduct!.getPriceByTradeType(widget.tradeType);
                  widget.onProductAdded(_selectedProduct!, _quantity, price);
                  Navigator.pop(context);
                },
                child: const Text('إضافة إلى الفاتورة', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
