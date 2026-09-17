import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import 'product_card_screen.dart';

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
      final productsList = await DatabaseHelper.instance.getProducts();
      setState(() {
        _products = productsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final buyPriceController = TextEditingController();
    final wholesalePriceController = TextEditingController();
    final retailPriceController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مادة جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم المادة *'),
              ),
              TextField(
                controller: buyPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'سعر الشراء'),
              ),
              TextField(
                controller: wholesalePriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'سعر الجملة'),
              ),
              TextField(
                controller: retailPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'سعر المفرق'),
              ),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الكمية الأولية'),
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final newProduct = Product(
                name: nameController.text.trim(),
                buyPrice: double.tryParse(buyPriceController.text) ?? 0.0,
                wholesalePrice: double.tryParse(wholesalePriceController.text) ?? 0.0,
                retailPrice: double.tryParse(retailPriceController.text) ?? 0.0,
                stockQuantity: double.tryParse(qtyController.text) ?? 0.0,
              );

              await DatabaseHelper.instance.insertProduct(newProduct);

              if (mounted) Navigator.pop(context);
              _loadProducts();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0277BD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المواد والمخزون'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مواد مسجلة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE1F5FE),
                          child: Text(
                            item.name.isNotEmpty ? item.name[0] : '?',
                            style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('الكمية: ${item.stockQuantity}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.retailPrice} ل.س',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'مفرق',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductCardScreen(product: item),
                            ),
                          );
                          if (updated == true) {
                            _loadProducts();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
