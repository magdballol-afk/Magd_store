import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String _invoiceType = 'مبيعات';
  
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _products = [];
  
  Map<String, dynamic>? _selectedContact;
  Map<String, dynamic>? _selectedProduct;

  // عناصر الفاتورة مع متحكم بالسعر لكل مادة لتعديله بسهولة
  final List<Map<String, dynamic>> _cartItems = [];

  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _paidController = TextEditingController(text: '0');

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    final contactsData = await db.query('contacts');
    final productsData = await db.query('products');

    setState(() {
      _contacts = contactsData;
      _products = productsData;
      _isLoading = false;
    });
  }

  void _addProductToCart(Map<String, dynamic> product) {
    final existingIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);
    
    setState(() {
      if (existingIndex >= 0) {
        // إذا كانت المادة موجودة سابقاً نكتفي بزيادة الكمية
        _cartItems[existingIndex]['quantity'] += 1.0;
      } else {
        // تحديد السعر الافتراضي بحسب نوع الفاتورة
        double price = 0.0;
        if (_invoiceType == 'مبيعات') {
          price = (product['retail_price'] ?? product['price'] ?? 0.0).toDouble();
        } else {
          price = (product['buy_price'] ?? product['cost_price'] ?? 0.0).toDouble();
        }

        _cartItems.add({
          'id': product['id'],
          'name': product['name'],
          'price': price,
          'quantity': 1.0,
          'priceController': TextEditingController(text: price.toStringAsFixed(2)),
        });
      }
      _selectedProduct = null;
    });
  }

  double _calculateSubtotal() {
    double sum = 0.0;
    for (var item in _cartItems) {
      sum += (item['price'] * item['quantity']);
    }
    return sum;
  }

  Future<void> _saveInvoice() async {
    if (_selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل / المورد أولاً')),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة مواد إلى الفاتورة')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;

    // 1. حساب القيم المالية
    final subtotal = _calculateSubtotal();
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final totalAmount = subtotal - discount;
    final paidAmount = double.tryParse(_paidController.text) ?? 0.0;
    final remainingAmount = totalAmount - paidAmount; // المبلغ المتبقي (الذمة)

    // 2. إدخال الفاتورة في جدول sales_invoices
    final invoiceId = await db.insert('sales_invoices', {
      'contact_name': _selectedContact!['name'],
      'type': _invoiceType,
      'date': DateTime.now().toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
    });

    // 3. إدخال عناصر الفاتورة وتحديث كمية المخزون لكل مادة
    for (var item in _cartItems) {
      await db.insert('invoice_items', {
        'invoice_id': invoiceId,
        'product_id': item['id'],
        'product_name': item['name'],
        'quantity': item['quantity'],
        'unit_price': item['price'],
        'total': item['price'] * item['quantity'],
      });

      // تحديث كمية المادة في المخزن
      final prodResult = await db.query('products', where: 'id = ?', whereArgs: [item['id']]);
      if (prodResult.isNotEmpty) {
        double currentStock = (prodResult.first['stock_quantity'] ?? prodResult.first['quantity'] ?? 0.0).toDouble();
        if (_invoiceType == 'مبيعات') {
          currentStock -= (item['quantity'] as double);
        } else {
          currentStock += (item['quantity'] as double);
        }

        await db.update(
          'products',
          {
            'stock_quantity': currentStock,
            'quantity': currentStock,
          },
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }
    }

    // 4. تحديث رصيد العميل / المورد في جدول contacts
    if (remainingAmount != 0) {
      final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [_selectedContact!['id']]);
      if (contactResult.isNotEmpty) {
        double currentBalance = (contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0).toDouble();

        // في المبيعات: المتبقي يزيد من ذمة العميل (مدين +)
        // في المشتريات: المتبقي ينقص الذمة / ينزل لحساب المورد (دائن -)
        if (_invoiceType == 'مبيعات') {
          currentBalance += remainingAmount;
        } else {
          currentBalance -= remainingAmount;
        }

        await db.update(
          'contacts',
          {
            'balance_syr': currentBalance,
            'balance': currentBalance,
          },
          where: 'id = ?',
          whereArgs: [_selectedContact!['id']],
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفاتورة وتحديث رصيد العميل بنجاح')),
      );
      Navigator.pop(context, true); // إرجاع true لتحديث قائمة الفواتير
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _paidController.dispose();
    for (var item in _cartItems) {
      if (item['priceController'] is TextEditingController) {
        (item['priceController'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اختيار نوع الفاتورة والعميل/المورد
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _invoiceType,
                          decoration: const InputDecoration(
                            labelText: 'نوع الفاتورة',
                            border: OutlineInputBorder(),
                          ),
                          items: ['مبيعات', 'مشتريات'].map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _invoiceType = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedContact,
                          hint: const Text('اختيار عميل/مورد'),
                          decoration: const InputDecoration(
                            labelText: 'العميل / المورد',
                            border: OutlineInputBorder(),
                          ),
                          items: _contacts.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c['name'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedContact = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // البحث عن مادة وتحديدها
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedProduct,
                    hint: const Text('بحث عن مادة لإضافتها...'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    items: _products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p['name']} (${p['retail_price'] ?? p['price'] ?? 0} ل.س)'),
                      );
                    }).toList(),
                    onChanged: (p) {
                      if (p != null) {
                        _addProductToCart(p);
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'عناصر الفاتورة:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // قائمة العناصر القابلة لتعديل السعر والكمية والحذف
                  _cartItems.isEmpty
                      ? const Center(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('لم يتم إضافة أي مادة بعد', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            final priceController = item['priceController'] as TextEditingController;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name'],
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        // زر الحذف بجانب المادة
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _cartItems.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // تعديل السعر المفرد
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: priceController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              labelText: 'السعر المفرد',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                item['price'] = double.tryParse(val) ?? 0.0;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // أزرار التحكم بالكمية
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                                onPressed: () {
                                                  setState(() {
                                                    if (item['quantity'] > 1) {
                                                      item['quantity'] -= 1.0;
                                                    } else {
                                                      _cartItems.removeAt(index);
                                                    }
                                                  });
                                                },
                                              ),
                                              Text(
                                                '${item['quantity']}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                                onPressed: () {
                                                  setState(() {
                                                    item['quantity'] += 1.0;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'الإجمالي: ${(item['price'] * item['quantity']).toStringAsFixed(2)} ل.س',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  const Divider(height: 30, thickness: 1.5),

                  // الإجماليات والخصم والمدفوع
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع الفرعي:', style: TextStyle(fontSize: 16)),
                      Text('${subtotal.toStringAsFixed(2)} ل.س', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'الخصم (ل.س)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _paidController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'المبلغ المدفوع (ل.س)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي النهائي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '${total.toStringAsFixed(2)} ل.س',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      onPressed: _saveInvoice,
                      child: const Text('حفظ الفاتورة', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
