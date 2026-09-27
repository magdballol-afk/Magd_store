import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

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
      _isLoading = false;
    });
  }

  void _navigateToProductForm([Map<String, dynamic>? product]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: product),
      ),
    );

    if (result == true) {
      _refreshProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('إدارة المنتجات والمواد'),
        backgroundColor: const Color(0xFF0277BD),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('لا توجد مواد مضافة'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الكمية: ${item['quantity']} | مفرق: ${item['retail_price']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF0277BD)),
                          onPressed: () => _navigateToProductForm(item),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0277BD),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _navigateToProductForm(),
      ),
    );
  }
}
