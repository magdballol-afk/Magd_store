import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query('products');
      setState(() {
        _products = data.map((item) => Product.fromJson(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final buyPriceController = TextEditingController();
    final wholesalePriceController = TextEditingController();
    final retailPriceController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // لمنع إغلاق النافذة بالخطأ أثناء الكتابة
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إضافة مادة جديدة', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم المادة *'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال اسم المادة';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: buyPriceController,
                    decoration: const InputDecoration(labelText: 'سعر الشراء'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: wholesalePriceController,
                    decoration: const InputDecoration(labelText: 'سعر الجملة'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: retailPriceController,
                    decoration: const InputDecoration(labelText: 'سعر المفرق'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'الكمية الأولية'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () async {
                // 1. التحقق من صحة المدخلات
                if (formKey.currentState!.validate()) {
                  try {
                    final db = await DatabaseHelper.instance.database;

                    final double buyPrice = double.tryParse(buyPriceController.text) ?? 0.0;
                    final double wholesalePrice = double.tryParse(wholesalePriceController.text) ?? 0.0;
                    final double retailPrice = double.tryParse(retailPriceController.text) ?? 0.0;
                    final double quantity = double.tryParse(quantityController.text) ?? 0.0;

                    final newProduct = Product(
                      name: nameController.text.trim(),
                      costPrice: buyPrice,
                      wholesalePrice: wholesalePrice,
                      retailPrice: retailPrice,
                      price: retailPrice,
                      quantity: quantity,
                    );

                    // 2. الحفظ في قاعدة البيانات
                    await db.insert('products', newProduct.toJson());

                    // 3. إغلاق النافذة وتحديث القائمة
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    _loadProducts();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إضافة المادة بنجاح')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
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
        title: const Text('إدارة المواد والمخزون'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('لا توجد مواد مضافة بعد'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الكمية: ${product.quantity} | سعر المفرق: ${product.retailPrice}'),
                        trailing: Text('${product.costPrice} ل.س', style: const TextStyle(color: Colors.green)),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0284C7),
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
