import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  
  final TextEditingController _searchController = TextEditingController();
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
      _allProducts = data;
      _filterProducts(_searchController.text);
      _isLoading = false;
    });
  }

  // دالة تصفية المنتجات بناءً على نص البحث
  void _filterProducts(String query) {
    if (query.trim().isEmpty) {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        return name.contains(query.trim().toLowerCase());
      }).toList();
    }
  }

  // النافذة المنبثقة المصغرة لتعديل خصائص المادة (3 حقول فقط)
  void _showEditDialog(Map<String, dynamic> product) {
    final currentRetailPrice = product['retail_price'] ?? product['price'] ?? 0.0;

    final nameController = TextEditingController(
      text: product['name']?.toString() ?? '',
    );
    final quantityController = TextEditingController(
      text: (product['quantity'] ?? 0.0).toString(),
    );
    final retailPriceController = TextEditingController(
      text: currentRetailPrice.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text(
              'تعديل خصائص المادة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. حقل اسم المادة
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المادة',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF0277BD)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. حقل الكمية الحالية
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'الكمية الحالية',
                    prefixIcon: const Icon(Icons.dns_outlined, color: Color(0xFF0277BD)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. حقل سعر البيع (مفرق) - retail_price
                TextField(
                  controller: retailPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'سعر البيع (مفرق)',
                    prefixIcon: const Icon(Icons.local_offer_outlined, color: Color(0xFF0277BD)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0277BD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newName = nameController.text.trim().isEmpty ? product['name'] : nameController.text.trim();
                final newQuantity = double.tryParse(quantityController.text.trim()) ?? (product['quantity'] ?? 0.0);
                final newRetailPrice = double.tryParse(retailPriceController.text.trim()) ?? currentRetailPrice;

                final Map<String, dynamic> updatedProduct = {
                  'id': product['id'],
                  'name': newName,
                  'quantity': newQuantity,
                  'retail_price': newRetailPrice,
                  'buy_price': product['buy_price'] ?? 0.0,
                  'half_wholesale_price': product['half_wholesale_price'] ?? 0.0,
                  'wholesale_price': product['wholesale_price'] ?? 0.0,
                };

                final rowsAffected = await DatabaseHelper.instance.updateProduct(updatedProduct);

                if (mounted) {
                  Navigator.pop(context);

                  if (rowsAffected > 0) {
                    await _refreshProducts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حفظ التعديلات بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('خطأ: لم يتم العثور على المادة لتحديثها'),
                        backgroundColor: Colors.red,
                      ),
                    );
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

  // الانتقال لشاشة إدراج مادة جديدة كاملة
  void _navigateToAddProductScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    if (result == true) {
      _refreshProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('إدارة المنتجات والمواد'),
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔑 حقل البحث السريع عن مادة
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _filterProducts(val);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مادة بالاسم...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0277BD)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _filterProducts('');
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0277BD), width: 1.5),
                      ),
                    ),
                  ),
                ),

                // عرض القائمة المفلترة
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد مواد مطابقة للبحث',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final item = _filteredProducts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'الكمية: ${item['quantity']} | مفرق: ${item['retail_price'] ?? 0.0}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF0277BD)),
                                  onPressed: () => _showEditDialog(item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0277BD),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مادة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _navigateToAddProductScreen,
      ),
    );
  }
}
