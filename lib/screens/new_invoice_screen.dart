import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  final String type; // 'sale' أو 'purchase'

  const NewInvoiceScreen({Key? key, required this.type}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedContactId;
  String _selectedContactName = 'عميل عام';
  final TextEditingController _contactSearchController = TextEditingController();
  final TextEditingController _itemSearchController = TextEditingController();

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _invoiceItems = [];

  double _discount = 0.0;
  double _paidAmount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final contactsData = await DatabaseHelper.instance.getContacts();
    final productsData = await DatabaseHelper.instance.getProducts();

    setState(() {
      _contacts = contactsData.map((c) => c.toMap()).toList();
      _products = productsData.map((p) => p.toMap()).toList();
      _isLoading = false;
    });
  }

  void _addItemToInvoice(Map<String, dynamic> product) {
    final existingIndex = _invoiceItems.indexWhere((item) => item['id'] == product['id']);
    final double price = widget.type == 'sale'
        ? ((product['sell_price'] ?? 0) as num).toDouble()
        : ((product['buy_price'] ?? 0) as num).toDouble();

    setState(() {
      if (existingIndex >= 0) {
        _invoiceItems[existingIndex]['quantity'] += 1;
      } else {
        _invoiceItems.add({
          'id': product['id'],
          'name': product['name'],
          'price': price,
          'quantity': 1,
        });
      }
    });
    _itemSearchController.clear();
  }

  double get _subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  double get _total {
    final result = _subtotal - _discount;
    return result < 0 ? 0 : result;
  }

  Future<void> _saveInvoice() async {
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة مادة واحدة على الأقل للفاتورة')),
      );
      return;
    }

    final String formattedDate = DateTime.now().toString().split(' ')[0];

    await DatabaseHelper.instance.addInvoice(
      type: widget.type,
      contactId: _selectedContactId,
      contactName: _selectedContactName,
      items: _invoiceItems,
      subtotal: _subtotal,
      discount: _discount,
      total: _total,
      paid: _paidAmount,
      date: formattedDate,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _contactSearchController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSale = widget.type == 'sale';

    return Scaffold(
      appBar: AppBar(
        title: Text(isSale ? 'فاتورة مبيعات جديدة' : 'فاتورة مشتريات جديدة'),
        backgroundColor: isSale ? const Color(0xFF0284C7) : const Color(0xFF059669),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اختيار الحساب / العميل
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: RawAutocomplete<Map<String, dynamic>>(
                              textEditingController: _contactSearchController,
                              focusNode: FocusNode(),
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final List<Map<String, dynamic>> allOptions = [
                                  {'id': null, 'name': isSale ? 'عميل عام' : 'مورد عام'},
                                  ..._contacts,
                                ];
                                if (textEditingValue.text.isEmpty) return allOptions;
                                return allOptions.where((option) {
                                  final name = option['name'].toString().toLowerCase();
                                  return name.contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              displayStringForOption: (option) => option['name'] ?? '',
                              onSelected: (selection) {
                                setState(() {
                                  _selectedContactId = selection['id'];
                                  _selectedContactName = selection['name'] ?? (isSale ? 'عميل عام' : 'مورد عام');
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: isSale ? 'اسم العميل' : 'اسم المورد',
                                    prefixIcon: const Icon(Icons.person),
                                    suffixIcon: controller.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              controller.clear();
                                              setState(() {
                                                _selectedContactId = null;
                                                _selectedContactName = isSale ? 'عميل عام' : 'مورد عام';
                                              });
                                            },
                                          )
                                        : null,
                                    border: const OutlineInputBorder(),
                                  ),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      width: MediaQuery.of(context).size.width - 56,
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);
                                          return ListTile(
                                            title: Text(option['name'] ?? ''),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // البحث عن مادة وإضافتها
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: RawAutocomplete<Map<String, dynamic>>(
                              textEditingController: _itemSearchController,
                              focusNode: FocusNode(),
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) return const [];
                                return _products.where((product) {
                                  final name = product['name'].toString().toLowerCase();
                                  return name.contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              displayStringForOption: (option) => option['name'] ?? '',
                              onSelected: (selection) => _addItemToInvoice(selection),
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'ابحث عن مادة لإضافتها...',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                  ),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      width: MediaQuery.of(context).size.width - 56,
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);
                                          final price = isSale ? option['sell_price'] : option['buy_price'];
                                          return ListTile(
                                            title: Text(option['name'] ?? ''),
                                            subtitle: Text('السعر: $price'),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // جدول/قائمة المواد المضافة
                        const Text(
                          'مواد الفاتورة:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        _invoiceItems.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(child: Text('لم يتم إضافة أي مادة بعد')),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _invoiceItems.length,
                                itemBuilder: (context, index) {
                                  final item = _invoiceItems[index];
                                  final double itemTotal = item['price'] * item['quantity'];

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'],
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text('السعر: ${item['price']}'),
                                              ],
                                            ),
                                          ),
                                          // تحكم الكمية
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                                onPressed: () {
                                                  setState(() {
                                                    if (item['quantity'] > 1) {
                                                      item['quantity']--;
                                                    } else {
                                                      _invoiceItems.removeAt(index);
                                                    }
                                                  });
                                                },
                                              ),
                                              Text('${item['quantity']}', style: const TextStyle(fontSize: 16)),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                                onPressed: () {
                                                  setState(() {
                                                    item['quantity']++;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${itemTotal.toStringAsFixed(2)}',
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),

                // شريط الحسابات والسداد في الأسفل
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المجموع الفرعي:'),
                          Text(
                            _subtotal.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'الخصم',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _discount = double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'المبلغ المدفوع',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _paidAmount = double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي النهائي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            _total.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSale ? const Color(0xFF0284C7) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSale ? const Color(0xFF0284C7) : const Color(0xFF059669),
                          ),
                          onPressed: _saveInvoice,
                          child: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
