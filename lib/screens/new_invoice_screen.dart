import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({
    super.key,
    this.existingInvoice,
  });

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _invoiceItems = [];

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();

  String _invoiceType = 'مبيعات';
  double _discount = 0.0;
  double _paidAmount = 0.0;

  List<Map<String, dynamic>> _contacts = [];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final contactsData = await db.query('contacts');
      final productsData = await db.query('products');

      setState(() {
        _contacts = contactsData;
        _products = productsData.map((item) => Product.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _subtotal {
    double total = 0.0;
    for (var item in _invoiceItems) {
      total += (item['price'] as double) * (item['quantity'] as double);
    }
    return total;
  }

  double get _grandTotal {
    double total = _subtotal - _discount;
    return total < 0 ? 0.0 : total;
  }

  double get _remainingAmount => _grandTotal - _paidAmount;

  void _addProductToInvoice(Product product) {
    setState(() {
      final existingIndex = _invoiceItems.indexWhere((item) => item['product_id'] == product.id);
      if (existingIndex >= 0) {
        _invoiceItems[existingIndex]['quantity'] += 1.0;
      } else {
        _invoiceItems.add({
          'product_id': product.id,
          'product_name': product.name,
          'price': _invoiceType == 'مبيعات' ? product.retailPrice : product.costPrice,
          'quantity': 1.0,
        });
      }
    });
  }

  Future<void> _saveInvoice() async {
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة منتج واحد على الأقل للفاتورة')),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final contactName = _contactController.text.trim();

      final invoiceData = {
        'contact_name': contactName.isNotEmpty ? contactName : 'عميل نقدي',
        'type': _invoiceType,
        'date': DateTime.now().toIso8601String(),
        'subtotal': _subtotal,
        'discount': _discount,
        'total_amount': _grandTotal,
        'paid_amount': _paidAmount,
        'remaining_amount': _remainingAmount,
      };

      final invoiceId = await db.insert('sales_invoices', invoiceData);

      for (var item in _invoiceItems) {
        await db.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['price'],
          'total': (item['price'] as double) * (item['quantity'] as double),
        });

        if (_invoiceType == 'مبيعات') {
          await db.rawUpdate(
            'UPDATE products SET quantity = quantity - ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        } else {
          await db.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [item['quantity'], item['product_id']],
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ الفاتورة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingInvoice == null ? 'فاتورة جديدة' : 'تعديل الفاتورة'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. نوع الفاتورة والعميل المتقدم
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _invoiceType,
                                  decoration: const InputDecoration(
                                    labelText: 'نوع الفاتورة',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'مبيعات', child: Text('مبيعات')),
                                    DropdownMenuItem(value: 'مشتريات', child: Text('مشتريات')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _invoiceType = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Autocomplete<String>(
                                  optionsBuilder: (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _contacts.map((c) => c['name'].toString());
                                    }
                                    return _contacts
                                        .map((c) => c['name'].toString())
                                        .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                  },
                                  onSelected: (String selection) {
                                    _contactController.text = selection;
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                    _contactController.text = controller.text;
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'العميل / المورد',
                                        prefixIcon: Icon(Icons.person_search),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. البحث المتقدم عن المنتجات
                          Autocomplete<Product>(
                            displayStringForOption: (Product option) => '${option.name} (${option.retailPrice} ل.س)',
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<Product>.empty();
                              }
                              return _products.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (Product selection) {
                              _addProductToInvoice(selection);
                              _productSearchController.clear();
                            },
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'بحث عن مادة لإضافتها...',
                                  prefixIcon: Icon(Icons.search, color: Color(0xFF0284C7)),
                                  border: OutlineInputBorder(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. قائمة عناصر الفاتورة المعروضة
                          const Text('عناصر الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),

                          _invoiceItems.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(20),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('لم يتم إضافة مواد للفاتورة بعد', style: TextStyle(color: Colors.grey)),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _invoiceItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _invoiceItems[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Text('${item['price']} ل.س × ${item['quantity']}', style: const TextStyle(color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (item['quantity'] > 1) {
                                                        item['quantity'] -= 1.0;
                                                      }
                                                    });
                                                  },
                                                ),
                                                Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                                  onPressed: () {
                                                    setState(() {
                                                      item['quantity'] += 1.0;
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      _invoiceItems.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          const Divider(height: 32),

                          // 4. الحسابات والخصم والمدفوع
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المجموع الفرعي:', style: TextStyle(fontSize: 15)),
                              Text('${_subtotal.toStringAsFixed(2)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'الخصم (ل.س)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setState(() {
                                      _discount = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'المبلغ المدفوع (ل.س)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setState(() {
                                      _paidAmount = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('الإجمالي النهائي:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${_grandTotal.toStringAsFixed(2)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0284C7))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('المتبقي (دين):'),
                                    Text('${_remainingAmount.toStringAsFixed(2)} ل.س', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // زر الحفظ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _saveInvoice,
                      child: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
