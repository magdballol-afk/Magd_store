import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/contact_model.dart';

class InvoiceItem {
  final Product product;
  double price;
  double quantity;

  InvoiceItem({
    required this.product,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice; // لتعديل فاتورة قائمة إن وجدت

  const NewInvoiceScreen({Key? key, this.existingInvoice}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  // عناصر الرأس
  String _currency = 'ليرة سورية';
  Contact? _selectedParty;
  final TextEditingController _partySearchController = TextEditingController();
  List<Contact> _partySuggestions = [];

  // بنود الفاتورة
  final List<InvoiceItem> _addedItems = [];

  // الحسابات والخصم
  bool _isPercentageDiscount = false;
  final TextEditingController _discountController = TextEditingController(text: '0.0');
  final TextEditingController _paidAmountController = TextEditingController();

  double _previousBalance = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      _loadExistingInvoiceData();
    }
  }

  void _loadExistingInvoiceData() {
    // تحميل بيانات الفاتورة السابقة عند التعديل
  }

  // حساب المجموع الفرعي
  double get _subtotal => _addedItems.fold(0.0, (sum, item) => sum + item.total);

  // حساب قيمة الخصم
  double get _discountAmount {
    final rawDiscount = double.tryParse(_discountController.text) ?? 0.0;
    if (_isPercentageDiscount) {
      return (_subtotal * rawDiscount) / 100;
    }
    return rawDiscount;
  }

  // الصافي
  double get _netTotal => _subtotal - _discountAmount;

  // المتبقي
  double get _remainingAmount {
    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return (_netTotal + _previousBalance) - paid;
  }

  // إكمال تلقائي للعملاء
  void _searchParties(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _partySuggestions = []);
      return;
    }
    final results = await _db.searchContacts(query); // جلب من جدول الأطراف
    setState(() => _partySuggestions = results);
  }

  // إضافة منتج للفاتورة عبر نافذة الحوار
  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddProductDialog(
        currency: _currency,
        onAdded: (product, price, quantity) {
          setState(() {
            _addedItems.add(InvoiceItem(
              product: product,
              price: price,
              quantity: quantity,
            ));
          });
        },
      ),
    );
  }

  // حفظ الفاتورة وتحديث قاعدة البيانات
  Future<void> _saveInvoice() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد العميل أولاً')),
      );
      return;
    }

    if (_addedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة منتج واحد على الأقل')),
      );
      return;
    }

    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;

    final invoiceData = {
      'party_id': _selectedParty!.id,
      'currency': _currency,
      'subtotal': _subtotal,
      'discount': _discountAmount,
      'net_total': _netTotal,
      'paid_amount': paid,
      'remaining_amount': _remainingAmount,
      'created_at': DateTime.now().toIso8601String(),
    };

    // حفظ الفاتورة وتحديث مخزون الأصناف ورصيد العميل في DatabaseHelper
    await _db.saveInvoiceWithDetails(invoiceData, _addedItems);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        centerTitle: true,
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
                const Text('عملة الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ليرة سورية', label: Text('ليرة سورية')),
                    ButtonSegment(value: 'دولار (\$)', label: Text('دولار (\$)')),
                  ],
                  selected: {_currency},
                  onSelectionChanged: (val) {
                    setState(() => _currency = val.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. اختيار العميل
            TextField(
              controller: _partySearchController,
              decoration: const InputDecoration(
                labelText: 'ابحث أو أدخل اسم العميل',
                prefixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchParties,
            ),
            if (_partySuggestions.isNotEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                child: ListView.builder(
                  itemCount: _partySuggestions.length,
                  itemBuilder: (context, i) {
                    final party = _partySuggestions[i];
                    return ListTile(
                      title: Text(party.name),
                      subtitle: Text(party.phone ?? ''),
                      onTap: () {
                        setState(() {
                          _selectedParty = party;
                          _partySearchController.text = party.name;
                          _previousBalance = party.balanceSyr; // الرصيد السوري كنموذج
                          _partySuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // 3. زر إضافة منتج
            OutlinedButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('إضافة منتج للفاتورة (مفرق)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

            const SizedBox(height: 16),
            const Text(':المنتجات المضافة', style: TextStyle(fontWeight: FontWeight.bold)),

            // 4. عرض المنتجات المضافة
            _addedItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('لم يتم إضافة أي منتج بعد', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _addedItems.length,
                    itemBuilder: (ctx, index) {
                      final item = _addedItems[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.product.name),
                          subtitle: Text('الكمية: ${item.quantity} × ${item.price} $_currency'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${item.total} $_currency', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() => _addedItems.removeAt(index));
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            const Divider(height: 32),

            // 5. الحسابات والمالية
            _buildSummaryRow('المجموع الفرعي:', '$_subtotal $_currency'),
            const SizedBox(height: 8),

            // حقل الخصم
            Row(
              children: [
                const Text('حسم الفاتورة الكلي:'),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [_isPercentageDiscount, !_isPercentageDiscount],
                  onPressed: (index) {
                    setState(() => _isPercentageDiscount = index == 0);
                  },
                  children: const [Text('%'), Text('مبلغ')],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _buildSummaryRow('صافي الفاتورة:', '$_netTotal $_currency', isBold: true, color: Colors.green),
            _buildSummaryRow('رصيد سابق مترتب:', '$_previousBalance $_currency', color: Colors.grey),

            const SizedBox(height: 8),
            // الدفعة المقبوضة
            TextField(
              controller: _paidAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الدفعة المقبوضة ($_currency)',
                prefixIcon: const Icon(Icons.money),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            _buildSummaryRow('الرصيد الحالي المتبقي:', '$_remainingAmount $_currency', isBold: true, color: Colors.green),

            const SizedBox(height: 24),

            // 6. أزرار الحفظ والطباعة
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveInvoice,
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ الفاتورة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    // أمر الطباعة الفورية
                  },
                  icon: const Icon(Icons.print),
                  style: IconButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}

// نافذة اختيار وإضافة منتج
class _AddProductDialog extends StatefulWidget {
  final String currency;
  final Function(Product product, double price, double quantity) onAdded;

  const _AddProductDialog({required this.currency, required this.onAdded});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');

  List<Product> _suggestions = [];
  Product? _selectedProduct;

  void _search(String text) async {
    if (text.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final res = await _db.searchProducts(text);
    setState(() => _suggestions = res);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة منتج'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(labelText: 'اسم المنتج'),
            onChanged: _search,
          ),
          if (_suggestions.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(_suggestions[i].name),
                  trailing: Text('${_suggestions[i].retailPrice}'),
                  onTap: () {
                    setState(() {
                      _selectedProduct = _suggestions[i];
                      _searchController.text = _suggestions[i].name;
                      _priceController.text = _suggestions[i].retailPrice.toString();
                      _suggestions = [];
                    });
                  },
                ),
              ),
            ),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'السعر (${widget.currency})'),
          ),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'الكمية'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            if (_selectedProduct != null) {
              final price = double.tryParse(_priceController.text) ?? 0.0;
              final qty = double.tryParse(_qtyController.text) ?? 1.0;
              widget.onAdded(_selectedProduct!, price, qty);
              Navigator.pop(context);
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
