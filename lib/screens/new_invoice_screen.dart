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

  final List<Map<String, dynamic>> _cartItems = [];

  final TextEditingController _contactSearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();
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

    final contactsData = await db.query('contacts', orderBy: 'name ASC');
    final productsData = await db.query('products', orderBy: 'name ASC');

    setState(() {
      _contacts = contactsData;
      _products = productsData;
      _isLoading = false;
    });
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة جهة اتصال جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                final id = await db.insert('contacts', {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'balance_syr': 0.0,
                });
                if (mounted) Navigator.pop(context);
                await _loadData();
                final newContact = _contacts.firstWhere((e) => e['id'] == id);
                setState(() {
                  _selectedContact = newContact;
                  _contactSearchController.text = newContact['name'] ?? '';
                });
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _addProductToCart(Map<String, dynamic> product) {
    final existingIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);

    setState(() {
      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity'] = ((_cartItems[existingIndex]['quantity'] as num) + 1.0).toDouble();
      } else {
        double price = 0.0;
        if (_invoiceType == 'مبيعات') {
          price = ((product['retail_price'] ?? product['price'] ?? 0.0) as num).toDouble();
        } else {
          price = ((product['buy_price'] ?? product['cost_price'] ?? 0.0) as num).toDouble();
        }

        _cartItems.add({
          'id': product['id'],
          'name': product['name'],
          'price': price,
          'quantity': 1.0,
          'priceController': TextEditingController(text: price.toStringAsFixed(2)),
        });
      }
      _productSearchController.clear();
    });
  }

  double _calculateSubtotal() {
    double sum = 0.0;
    for (var item in _cartItems) {
      final price = (item['price'] as num).toDouble();
      final qty = (item['quantity'] as num).toDouble();
      sum += (price * qty);
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

    final subtotal = _calculateSubtotal();
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final totalAmount = subtotal - discount;
    final paidAmount = double.tryParse(_paidController.text) ?? 0.0;
    final remainingAmount = totalAmount - paidAmount;

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

    for (var item in _cartItems) {
      final double price = (item['price'] as num).toDouble();
      final double qty = (item['quantity'] as num).toDouble();

      await db.insert('invoice_items', {
        'invoice_id': invoiceId,
        'product_id': item['id'],
        'product_name': item['name'],
        'quantity': qty,
        'unit_price': price,
        'total': price * qty,
      });

      final prodResult = await db.query('products', where: 'id = ?', whereArgs: [item['id']]);
      if (prodResult.isNotEmpty) {
        double currentStock = ((prodResult.first['stock_quantity'] ?? prodResult.first['quantity'] ?? 0.0) as num).toDouble();
        if (_invoiceType == 'مبيعات') {
          currentStock -= qty;
        } else {
          currentStock += qty;
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

    if (remainingAmount != 0) {
      final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [_selectedContact!['id']]);
      if (contactResult.isNotEmpty) {
        double currentBalance = ((contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0) as num).toDouble();

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
        const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _contactSearchController.dispose();
    _productSearchController.dispose();
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
                  // اختيار نوع الفاتورة
                  DropdownButtonFormField<String>(
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
                  const SizedBox(height: 12),

                  // بحث عن العميل + زر إضافة
                  Row(
                    children: [
                      Expanded(
                        child: RawAutocomplete<Map<String, dynamic>>(
                          textEditingController: _contactSearchController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) return _contacts;
                            return _contacts.where((option) {
                              final name = option['name'].toString().toLowerCase();
                              final phone = option['phone']?.toString().toLowerCase() ?? '';
                              final input = textEditingValue.text.toLowerCase();
                              return name.contains(input) || phone.contains(input);
                            });
                          },
                          displayStringForOption: (option) => option['name'] ?? '',
                          onSelected: (selection) {
                            setState(() => _selectedContact = selection);
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'اسم العميل / المورد (ابحث هنا)',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          controller.clear();
                                          setState(() => _selectedContact = null);
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
                                  width: MediaQuery.of(context).size.width - 80,
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option['name'] ?? ''),
                                        subtitle: Text(option['phone'] ?? 'بدون رقم هاتف'),
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
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.person_add),
                        onPressed: _showAddContactDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // بحث متقدم عن المادة
                  RawAutocomplete<Map<String, dynamic>>(
                    textEditingController: _productSearchController,
                    focusNode: FocusNode(),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _products;
                      return _products.where((option) {
                        final name = option['name'].toString().toLowerCase();
                        final input = textEditingValue.text.toLowerCase();
                        return name.contains(input);
                      });
                    },
                    displayStringForOption: (option) => option['name'] ?? '',
                    onSelected: (selection) {
                      _addProductToCart(selection);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'بحث عن مادة لإضافتها...',
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
                            width: MediaQuery.of(context).size.width - 32,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                final price = option['retail_price'] ?? option['price'] ?? 0;
                                return ListTile(
                                  title: Text(option['name'] ?? ''),
                                  subtitle: Text('السعر: $price ل.س'),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'عناصر الفاتورة:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // قائمة المواد المضافة للفاتورة (تحديد السعر والكمية وحذف)
                  _cartItems.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('لم يتم إضافة أي مادة بعد', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            final priceController = item['priceController'] as TextEditingController;
                            final double price = (item['price'] as num).toDouble();
                            final double qty = (item['quantity'] as num).toDouble();

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
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                                onPressed: () {
                                                  setState(() {
                                                    if (qty > 1) {
                                                      item['quantity'] = qty - 1.0;
                                                    } else {
                                                      _cartItems.removeAt(index);
                                                    }
                                                  });
                                                },
                                              ),
                                              Text(
                                                '$qty',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                                onPressed: () {
                                                  setState(() {
                                                    item['quantity'] = qty + 1.0;
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
                                        'الإجمالي: ${(price * qty).toStringAsFixed(2)} ل.س',
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
