import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  // تصحيح المُنشئ هنا ليتوافق مع أحدث إصدارات Flutter وبدون أخطاء Syntax
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

  String? _selectedContact;
  String _invoiceType = 'مبيعات'; // أو 'مشتريات'
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

      // جلب العملاء/الموردين
      final contactsData = await db.query('contacts');

      // جلب المنتجات
      final productsData = await db.query('products');

      setState(() {
        _contacts = contactsData;
        _products = productsData.map((item) {
          // تصحيح جلب أسعار وشروط إنشاء كائن Product ليتوافق مع الموديل
          return Product.fromJson(item);
        }).toList();
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

  double get _remainingAmount {
    return _grandTotal - _paidAmount;
  }

  void _addProductToInvoice(Product product) {
    setState(() {
      final existingIndex = _invoiceItems.indexWhere((item) => item['product_id'] == product.id);
      if (existingIndex >= 0) {
        _invoiceItems[existingIndex]['quantity'] += 1.0;
      } else {
        _invoiceItems.add({
          'product_id': product.id,
          'product_name': product.name,
          'price': _invoiceType == 'مبيعات' ? product.retailPrice : product.buyPrice,
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

      final invoiceData = {
        'contact_name': _selectedContact ?? 'عميل نقدي',
        'type': _invoiceType,
        'date': DateTime.now().toIso8601String(),
        'subtotal': _subtotal,
        'discount': _discount,
        'total_amount': _grandTotal,
        'paid_amount': _paidAmount,
        'remaining_amount': _remainingAmount,
      };

      final invoiceId = await db.insert('sales_invoices', invoiceData);

      // حفظ عناصر الفاتورة
      for (var item in _invoiceItems) {
        await db.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item['product_id'],
          'product_name': item['product_name'],
          'quantity': item['quantity'],
          'unit_price': item['price'],
          'total': (item['price'] as double) * (item['quantity'] as double),
        });

        // تحديث الكمية والمخزون
        if (_invoiceType == 'مبيعات') {
          await db.rawUpdate(
            'UPDATE products SET stock_quantity = stock_quantity - ?, quantity = quantity - ? WHERE id = ?',
            [item['quantity'], item['quantity'], item['product_id']],
          );
        } else {
          await db.rawUpdate(
            'UPDATE products SET stock_quantity = stock_quantity + ?, quantity = quantity + ? WHERE id = ?',
            [item['quantity'], item['quantity'], item['product_id']],
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
                          // نوع الفاتورة والعميل
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _invoiceType,
                                  decoration: const InputDecoration(
                                    labelText: 'نوع الفاتورة',
                                    border: OutlineInputBorder(),
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedContact,
                                  decoration: const InputDecoration(
                                    labelText: 'العميل / المورد',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _contacts.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c['name'].toString(),
                                      child: Text(c['name'].toString()),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedContact = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // اختيار المنتجات
                          const Text('إضافة منتجات:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final p = _products[index];
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ActionChip(
                                    label: Text('${p.name} (${p.retailPrice} ل.س)'),
                                    onPressed: () => _addProductToInvoice(p),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 32),

                          // قائمة عناصر الفاتورة المختارة
                          const Text('عناصر الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _invoiceItems.length,
                            itemBuilder: (context, index) {
                              final item = _invoiceItems[index];
                              return Card(
                                child: ListTile(
                                  title: Text(item['product_name']),
                                  subtitle: Text('${item['price']} ل.س x ${item['quantity']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            if (item['quantity'] > 1) {
                                              item['quantity'] -= 1.0;
                                            } else {
                                              _invoiceItems.removeAt(index);
                                            }
                                          });
                                        },
                                      ),
                                      Text('${item['quantity']}'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            item['quantity'] += 1.0;
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

                          // ملخص المبالغ والخصم
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المجموع الفرعي:'),
                              Text('${_subtotal.toStringAsFixed(2)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
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
                          const SizedBox(height: 8),
                          TextFormField(
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
                        padding: const EdgeInsets.vertical: 14,
                      ),
                      onPressed: _saveInvoice,
                      child: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
