import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({Key? key, this.existingInvoice}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String _selectedCurrency = 'ليرة سورية';
  String _selectedDealType = 'مفرق';
  final List<Map<String, dynamic>> _invoiceItems = [];

  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0.0');
  final TextEditingController _paidController = TextEditingController();

  double _subtotal = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      // إذا كان هناك فاتورة سابقة للتعديل
      _clientController.text = widget.existingInvoice!['client_name'] ?? '';
    }
  }

  void _calculateTotals() {
    double sum = 0.0;
    for (var item in _invoiceItems) {
      sum += (item['total'] as double);
    }
    setState(() {
      _subtotal = sum;
      double discount = double.tryParse(_discountController.text) ?? 0.0;
      _total = sum - discount;
    });
  }

  void _showAddProductDialog() async {
    final allProducts = await DatabaseHelper.instance.getAllProducts();
    Map<String, dynamic>? selectedProduct;
    final TextEditingController priceController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulWidget(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة منتج للفاتورة', textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) => option['name'] as String,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.length < 2) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return allProducts.where((product) {
                          final name = (product['name'] as String).toLowerCase();
                          final barcode = (product['barcode'] as String?)?.toLowerCase() ?? '';
                          final query = textEditingValue.text.toLowerCase();
                          return name.contains(query) || barcode.contains(query);
                        });
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        selectedProduct = selection;
                        double defaultPrice = (selection['price_retail'] as num?)?.toDouble() ?? 0.0;
                        if (_selectedDealType == 'نصف جملة') {
                          defaultPrice = (selection['price_half_wholesale'] as num?)?.toDouble() ?? defaultPrice;
                        } else if (_selectedDealType == 'جملة') {
                          defaultPrice = (selection['price_wholesale'] as num?)?.toDouble() ?? defaultPrice;
                        }

                        setDialogState(() {
                          priceController.text = defaultPrice.toString();
                        });
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'اسم المنتج أو الباركود',
                            hintText: 'اكتب حرفين للبحث...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topRight,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              height: 200,
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option['name']),
                                    subtitle: Text('الكمية: ${option['quantity']} | السعر: ${option['price_retail']}'),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'السعر',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String name = selectedProduct != null ? selectedProduct!['name'] : '';
                    final double? price = double.tryParse(priceController.text);
                    final double? qty = double.tryParse(quantityController.text);

                    if (name.isNotEmpty && price != null && qty != null && qty > 0) {
                      setState(() {
                        _invoiceItems.add({
                          'product_id': selectedProduct?['id'],
                          'product_name': name,
                          'price': price,
                          'quantity': qty,
                          'total': price * qty,
                        });
                        _calculateTotals();
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('إضافة'),
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
      appBar: AppBar(title: const Text('فاتورة جديدة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(
                labelText: 'اسم العميل',
                prefixIcon: Icon(Icons.person_search),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('إضافة منتج للفاتورة'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = _invoiceItems[index];
                  return ListTile(
                    title: Text(item['product_name']),
                    subtitle: Text('الكمية: ${item['quantity']} × ${item['price']}'),
                    trailing: Text('${item['total']}'),
                  );
                },
              ),
            ),
            Text('المجموع: $_subtotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                // حفظ الفاتورة
              },
              child: const Text('حفظ الفاتورة'),
            ),
          ],
        ),
      ),
    );
  }
}
