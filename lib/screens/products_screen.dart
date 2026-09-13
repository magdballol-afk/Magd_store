import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  // متحكمات الحقول عند إضافة منتج جديد
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceRetailController = TextEditingController();
  final _priceHalfWholesaleController = TextEditingController();
  final _priceWholesaleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  // جلب كافة المنتجات من قاعدة البيانات
  Future<void> _refreshProducts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  // إضافة منتج جديد
  Future<void> _addProduct() async {
    if (_nameController.text.isEmpty) return;

    await DatabaseHelper.instance.insertProduct({
      'name': _nameController.text,
      'barcode': _barcodeController.text.isEmpty ? null : _barcodeController.text,
      'category': _categoryController.text,
      'quantity': double.tryParse(_quantityController.text) ?? 0.0,
      'price_retail': double.tryParse(_priceRetailController.text) ?? 0.0,
      'price_half_wholesale': double.tryParse(_priceHalfWholesaleController.text) ?? 0.0,
      'price_wholesale': double.tryParse(_priceWholesaleController.text) ?? 0.0,
    });

    _clearControllers();
    Navigator.of(context).pop();
    _refreshProducts(); // تحديث القائمة تلقائياً
  }

  // حذف منتج
  Future<void> _deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _refreshProducts();
  }

  void _clearControllers() {
    _nameController.clear();
    _barcodeController.clear();
    _categoryController.clear();
    _quantityController.clear();
    _priceRetailController.clear();
    _priceHalfWholesaleController.clear();
    _priceWholesaleController.clear();
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة مادة جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم المادة *')),
              TextField(controller: _barcodeController, decoration: const InputDecoration(labelText: 'الباركود')),
              TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'الصنف')),
              TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية الأولية')),
              TextField(controller: _priceRetailController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر المفرق')),
              TextField(controller: _priceHalfWholesaleController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر نصف الجملة')),
              TextField(controller: _priceWholesaleController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الجملة')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: _addProduct, child: const Text('حفظ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنتجات والمستودع'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('لا توجد منتجات مسجلة حالياً'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'الكمية: ${item['quantity']} | مفرق: ${item['price_retail']} | جملة: ${item['price_wholesale']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(item['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
