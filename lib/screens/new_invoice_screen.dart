import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({super.key, this.existingInvoice});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _invoiceType = 'مبيعات';
  int? _selectedPartyId;
  String? _selectedPartyName;
  final TextEditingController _notesController = TextEditingController();
  
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _allParties = [];
  List<Map<String, dynamic>> _invoiceItems = [];
  
  double _totalAmount = 0.0;
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
      final products = await db.query('products', orderBy: 'name ASC');
      final parties = await db.query('parties', orderBy: 'name ASC');

      setState(() {
        _allProducts = products;
        _allParties = parties;
      });

      if (widget.existingInvoice != null) {
        _invoiceType = widget.existingInvoice!['type'] ?? 'مبيعات';
        _selectedPartyId = widget.existingInvoice!['party_id'];
        _notesController.text = widget.existingInvoice!['notes'] ?? '';
        _totalAmount = (widget.existingInvoice!['total'] ?? 0.0).toDouble();

        final items = await db.query(
          'invoice_items',
          where: 'invoice_id = ?',
          whereArgs: [widget.existingInvoice!['id']],
        );

        setState(() {
          _invoiceItems = List<Map<String, dynamic>>.from(items);
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _invoiceItems) {
      double qty = (item['quantity'] ?? 0.0).toDouble();
      double price = (item['price'] ?? 0.0).toDouble();
      total += (qty * price);
    }
    setState(() {
      _totalAmount = total;
    });
  }

  void _showAddItemDialog() {
    int? selectedProductId;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة مادة للفاتورة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedProductId,
                      items: _allProducts.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['id'] as int,
                          child: Text(p['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedProductId = val;
                            final p = _allProducts.firstWhere((element) => element['id'] == val);
                            priceController.text = (p['price'] ?? 0).toString();
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'اختر المادة'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الكمية'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر الوحدة'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProductId == null) return;
                    final product = _allProducts.firstWhere((p) => p['id'] == selectedProductId);
                    
                    setState(() {
                      _invoiceItems.add({
                        'product_id': selectedProductId,
                        'product_name': product['name'],
                        'quantity': double.tryParse(qtyController.text) ?? 1.0,
                        'price': double.tryParse(priceController.text) ?? 0.0,
                      });
                      _calculateTotal();
                    });
                    Navigator.pop(context);
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

  Future<void> _saveInvoice() async {
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة مادة واحدة على الأقل للفاتورة')),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      
      int invoiceId;
      if (widget.existingInvoice != null) {
        invoiceId = widget.existingInvoice!['id'];
        await db.update(
          'invoices',
          {
            'type': _invoiceType,
            'party_id': _selectedPartyId,
            'total': _totalAmount,
            'notes': _notesController.text.trim(),
            'date': DateTime.now().toString().split('.')[0],
          },
          where: 'id = ?',
          whereArgs: [invoiceId],
        );
        await db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      } else {
        invoiceId = await db.insert('invoices', {
          'type': _invoiceType,
          'party_id': _selectedPartyId,
          'total': _totalAmount,
          'notes': _notesController.text.trim(),
          'date': DateTime.now().toString().split('.')[0],
        });
      }

      for (var item in _invoiceItems) {
        await db.insert('invoice_items', {
          'invoice_id': invoiceId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ الفاتورة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingInvoice != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل فاتورة #${widget.existingInvoice!['id']}' : 'إنشاء فاتورة جديدة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveInvoice,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _invoiceType,
                            items: const [
                              DropdownMenuItem(value: 'مبيعات', child: Text('فاتورة مبيعات')),
                              DropdownMenuItem(value: 'مشتريات', child: Text('فاتورة مشتريات')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _invoiceType = val);
                            },
                            decoration: const InputDecoration(
                              labelText: 'نوع الفاتورة',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedPartyId,
                            items: _allParties.map((p) {
                              return DropdownMenuItem<int>(
                                value: p['id'] as int,
                                child: Text(p['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedPartyId = val);
                            },
                            decoration: const InputDecoration(
                              labelText: 'الجهة / العميل',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات وتفاصيل الفاتورة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('بنود الفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: _showAddItemDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة مادة'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: _invoiceItems.isEmpty
                          ? const Center(child: Text('لم يتم إضافة أي مواد بعد'))
                          : ListView.builder(
                              itemCount: _invoiceItems.length,
                              itemBuilder: (context, index) {
                                final item = _invoiceItems[index];
                                final double qty = (item['quantity'] ?? 0.0).toDouble();
                                final double price = (item['price'] ?? 0.0).toDouble();
                                final double subtotal = qty * price;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(item['product_name'] ?? 'مادة غير محددة'),
                                    subtitle: Text('الكمية: $qty × السعر: $price'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$subtotal ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _invoiceItems.removeAt(index);
                                              _calculateTotal();
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي العام:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '$_totalAmount ل.س',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        onPressed: _saveInvoice,
                        child: Text(isEditing ? 'تحديث وتأكيد الفاتورة' : 'حفظ وإصدار الفاتورة'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
