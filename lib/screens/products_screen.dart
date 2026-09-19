import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getProducts();
    setState(() {
      _products = data;
      _filteredProducts = data;
      _isLoading = false;
    });
    _filterProducts(_searchController.text);
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  // 1. نافذة إضافة أو تعديل مادة مع الأسعار المتقدمة
  void _showAddEditProductDialog([Map<String, dynamic>? product]) {
    final bool isEdit = product != null;

    final nameController = TextEditingController(text: isEdit ? product['name'] : '');
    final qtyController = TextEditingController(text: isEdit ? product['quantity'].toString() : '0');
    final purchasePriceController = TextEditingController(text: isEdit ? (product['purchase_price'] ?? 0.0).toString() : '0');
    final retailPriceController = TextEditingController(text: isEdit ? (product['price'] ?? 0.0).toString() : '0');
    final semiPriceController = TextEditingController(text: isEdit ? (product['semi_wholesale_price'] ?? 0.0).toString() : '0');
    final wholesalePriceController = TextEditingController(text: isEdit ? (product['wholesale_price'] ?? 0.0).toString() : '0');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'تعديل خصائص المادة' : 'إضافة مادة جديدة'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم المادة', border: OutlineInputBorder()),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'يرجى إدخال اسم المادة' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'الكمية الحالية', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: purchasePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'سعر الشراء', border: OutlineInputBorder(), prefixIcon: Icon(Icons.shopping_bag_outlined)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: retailPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'سعر البيع (مفرق)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sell_outlined)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: semiPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'سعر نصف الجملة', border: OutlineInputBorder(), prefixIcon: Icon(Icons.storefront_outlined)),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: wholesalePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'سعر الجملة', border: OutlineInputBorder(), prefixIcon: Icon(Icons.warehouse_outlined)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0)),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final Map<String, dynamic> data = {
                  'name': nameController.text.trim(),
                  'quantity': double.tryParse(qtyController.text.trim()) ?? 0.0,
                  'purchase_price': double.tryParse(purchasePriceController.text.trim()) ?? 0.0,
                  'price': double.tryParse(retailPriceController.text.trim()) ?? 0.0,
                  'semi_wholesale_price': double.tryParse(semiPriceController.text.trim()) ?? 0.0,
                  'wholesale_price': double.tryParse(wholesalePriceController.text.trim()) ?? 0.0,
                };

                if (isEdit) {
                  await DatabaseHelper.instance.updateProduct(product['id'], data);
                } else {
                  await DatabaseHelper.instance.insertProduct(data);
                }

                if (mounted) {
                  Navigator.pop(context);
                  _refreshProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'تم تعديل المادة بنجاح' : 'تمت إضافة المادة بنجاح')),
                  );
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 2. كشف حركة المادة مع الفلترة والتحويل للفاتورة
  void _showProductMovementDialog(Map<String, dynamic> product) async {
    final movements = await DatabaseHelper.instance.getProductMovements(product['id']);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String filterAccount = '';
        DateTimeRange? selectedDateRange;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredMovements = movements.where((m) {
              final contactName = (m['contact_name'] ?? '').toString().toLowerCase();
              final matchesAccount = contactName.contains(filterAccount.toLowerCase());

              bool matchesDate = true;
              if (selectedDateRange != null && m['date'] != null) {
                final date = DateTime.tryParse(m['date'].toString());
                if (date != null) {
                  matchesDate = date.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                      date.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
                }
              }
              return matchesAccount && matchesDate;
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'كشف حركة المادة: ${product['name']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // أدوات الفلترة (تاريخ + اسم حساب)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'فلترة باسم الحساب/العميل',
                                border: OutlineInputBorder(),
                                isDense: true,
                                prefixIcon: Icon(Icons.person_search, size: 20),
                              ),
                              onChanged: (val) => setSheetState(() => filterAccount = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.date_range, color: selectedDateRange != null ? Colors.indigo : Colors.grey),
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDateRange = picked);
                              }
                            },
                          ),
                          if (selectedDateRange != null)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () => setSheetState(() => selectedDateRange = null),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // القائمة الحركية
                      Expanded(
                        child: filteredMovements.isEmpty
                            ? const Center(child: Text('لا توجد حركات مسجلة لهذه المادة وفق المحددات'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredMovements.length,
                                itemBuilder: (context, index) {
                                  final m = filteredMovements[index];
                                  final bool isSale = m['invoice_type'] == 'sale';

                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isSale ? Colors.red.shade100 : Colors.green.shade100,
                                        child: Icon(
                                          isSale ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: isSale ? Colors.red : Colors.green,
                                        ),
                                      ),
                                      title: Text('${isSale ? 'مبيعات' : 'مشتريات'} - فاتورة #${m['invoice_id']}'),
                                      subtitle: Text('الحساب: ${m['contact_name']}\nالتاريخ: ${m['date']} | الكمية: ${m['quantity']}'),
                                      trailing: Text(
                                        'الإجمالي: ${m['total']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showInvoiceDetailsDialog(m['invoice_id']);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 3. عرض الفاتورة المرتبطة بالضغط على الحركة
  void _showInvoiceDetailsDialog(int invoiceId) async {
    final db = await DatabaseHelper.instance.database;
    final invoices = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);

    if (invoices.isEmpty || !mounted) return;

    final invoice = invoices.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تفاصيل الفاتورة #${invoice['id']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نوع الفاتورة: ${invoice['type'] == 'sale' ? 'مبيعات' : 'مشتريات'}'),
              Text('الحساب / العميل: ${invoice['contact_name']}'),
              Text('التاريخ: ${invoice['date']}'),
              const Divider(),
              Text('الصافي الكلي: ${invoice['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات والمواد'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // حقل البحث المتقدم العلوي
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'بحث متقدم عن مادة...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterProducts,
                  ),
                ),

                // قائمة المنتجات السفلية
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('لا توجد مواد مضافة'))
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final double retailPrice = (product['price'] as num?)?.toDouble() ?? 0.0;
                            final double qty = (product['quantity'] as num?)?.toDouble() ?? 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(
                                  product['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('الكمية: $qty | مفرق: $retailPrice | شراء: ${product['purchase_price']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.analytics_outlined, color: Colors.blue),
                                      tooltip: 'كشف حركة المادة',
                                      onPressed: () => _showProductMovementDialog(product),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.indigo),
                                      tooltip: 'تعديل خصائص المادة',
                                      onPressed: () => _showAddEditProductDialog(product),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditProductDialog(),
        backgroundColor: const Color(0xFF5C6BC0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مادة', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
