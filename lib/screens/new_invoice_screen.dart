import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _products = [];

  int? _selectedContactId;
  String? _selectedContactName;

  // قائمة المواد المضافة للفاتورة
  final List<Map<String, dynamic>> _invoiceItems = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final contactsData = await DatabaseHelper.instance.getContacts();
    final productsData = await DatabaseHelper.instance.getProducts();

    setState(() {
      _contacts = contactsData;
      _products = productsData;
      _isLoading = false;
    });
  }

  // حساب الإجمالي الكلي للفاتورة
  double get _totalAmount {
    return _invoiceItems.fold(0.0, (sum, item) {
      final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final double qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      return sum + (price * qty);
    });
  }

  // نافذة اختيار المادة وتحديد السعر والكمية
  void _showAddItemDialog() {
    Map<String, dynamic>? selectedProduct;
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

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
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: const InputDecoration(
                        labelText: 'اختر المادة',
                        border: OutlineInputBorder(),
                      ),
                      items: _products.map((prod) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: prod,
                          child: Text(prod['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedProduct = val;
                          if (val != null) {
                            priceController.text = (val['price'] ?? 0.0).toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'السعر (يمكنك تعديله)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'الكمية (تقبل فواصل مثل 1.5)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit_note),
                      ),
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
                    if (selectedProduct == null) return;

                    final double price = double.tryParse(priceController.text.trim()) ?? 0.0;
                    final double quantity = double.tryParse(quantityController.text.trim()) ?? 0.0;

                    if (quantity <= 0) return;

                    setState(() {
                      _invoiceItems.add({
                        'product_id': selectedProduct!['id'],
                        'name': selectedProduct!['name'],
                        'price': price,
                        'quantity': quantity,
                      });
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
        const SnackBar(content: Text('يرجى إضافة مادة واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final Map<String, dynamic> invoiceData = {
      'contact_id': _selectedContactId,
      'contact_name': _selectedContactName ?? 'عام / غير محدد',
      'total_amount': _totalAmount,
      'date': DateTime.now().toString().split(' ')[0],
    };

    // الاستدُعاء يمرر Map لتفادي خطأ Too few positional arguments
    await DatabaseHelper.instance.addInvoice(invoiceData);

    // إذا كان للعميل حساب، يتم تحديث رصيده المالي
    if (_selectedContactId != null) {
      await DatabaseHelper.instance.updateContactBalance(_selectedContactId, _totalAmount);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'اختر الحساب / العميل (اختياري)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    value: _selectedContactId,
                    items: _contacts.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedContactId = val;
                        _selectedContactName = _contacts.firstWhere(
                          (element) => element['id'] == val,
                          orElse: () => {'name': 'عام / غير محدد'},
                        )['name'];
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مواد الفاتورة:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة مادة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _invoiceItems.isEmpty
                        ? const Center(child: Text('لا توجد مواد مضافة بعد'))
                        : ListView.builder(
                            itemCount: _invoiceItems.length,
                            itemBuilder: (context, index) {
                              final item = _invoiceItems[index];
                              final double subtotal = (item['price'] as double) * (item['quantity'] as double);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(item['name']),
                                  subtitle: Text('الكمية: ${item['quantity']} × السعر: ${item['price']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        subtotal.toStringAsFixed(2),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _invoiceItems.removeAt(index);
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
                  const Divider(thickness: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي الكلي:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _totalAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C6BC0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C6BC0),
                      ),
                      onPressed: _isSaving ? null : _saveInvoice,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'حفظ الفاتورة',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
