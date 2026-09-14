import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'product_movement_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final rawData = await db.query('products', orderBy: 'name ASC');
      setState(() {
        _allProducts = rawData;
        _filteredProducts = rawData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    final filtered = _allProducts.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final code = product['code']?.toString().toLowerCase() ?? '';
      final input = query.toLowerCase();
      return name.contains(input) || code.contains(input);
    }).toList();

    setState(() {
      _filteredProducts = filtered;
    });
  }

  // نافذة تعديل خصائص المادة
  void _showEditProductDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']?.toString());
    final priceController = TextEditingController(text: product['price']?.toString());
    final quantityController = TextEditingController(text: product['quantity']?.toString());
    final unitController = TextEditingController(text: product['unit']?.toString() ?? 'قطعة');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعديل المادة: ${product['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المادة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'الكمية المتوفرة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'الوحدة (مثال: قطعة، كيلو)', border: OutlineInputBorder()),
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
                final db = await DatabaseHelper.instance.database;
                await db.update(
                  'products',
                  {
                    'name': nameController.text.trim(),
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'quantity': double.tryParse(quantityController.text) ?? 0.0,
                    'unit': unitController.text.trim(),
                  },
                  where: 'id = ?',
                  whereArgs: [product['id']],
                );

                if (mounted) Navigator.pop(context);
                _loadProducts();
              },
              child: const Text('حفظ التعديلات'),
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
        actions: [
          // زر الانتقال لكشف حركة المادة
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'كشف حركة مادة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductMovementScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // حقل البحث المتقدم
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                labelText: 'بحث عن مادة بالاسم أو الكود...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          
          // زر كشف حركة المادة المباشر
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
              icon: const Icon(Icons.receipt_long),
              label: const Text('كشف حركة مادة تفصيلي'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductMovementScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // قائمة عرض المواد
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('لا توجد مواد مطابقة للبحث'))
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final item = _filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(
                                item['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'الكمية: ${item['quantity'] ?? 0} ${item['unit'] ?? ''} | السعر: ${item['price'] ?? 0}',
                              ),
                              trailing: const Icon(Icons.edit_note, color: Colors.blue),
                              onTap: () => _showEditProductDialog(item),
                            );
                          },
                        ),
          ),
        ],
      ),
    );
  }
}
