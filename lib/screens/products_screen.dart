import 'package:flutter/material.dart';
import 'item_movement_filter_screen.dart';
import 'product_card_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // قائمة المنتجات الأصلية (قاعدة البيانات الوهمية)
  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': 'PROD-01',
      'name': 'شامبو بانتين 400 مل',
      'category': 'العناية الشخصية',
      'price': 12500.0,
      'stock': 45,
      'status': 'متوفر',
      'barcode': '6221001234567',
    },
    {
      'id': 'PROD-02',
      'name': 'معجون أسنان كولجيت',
      'category': 'العناية الشخصية',
      'price': 8000.0,
      'stock': 3,
      'status': 'قارب على الانتهاء',
      'barcode': '6221009876543',
    },
    {
      'id': 'PROD-03',
      'name': 'صابون دوف 100غ',
      'category': 'منظفات',
      'price': 4500.0,
      'stock': 120,
      'status': 'متوفر',
      'barcode': '6221005554443',
    },
    {
      'id': 'PROD-04',
      'name': 'مناديل فاين 500 منديل',
      'category': 'ورقيات',
      'price': 15000.0,
      'stock': 0,
      'status': 'نفذت الكمية',
      'barcode': '6221001112223',
    },
  ];

  // القائمة المعروضة حسب نتيجة البحث المتقدم
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_allProducts);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        // البحث المتقدم: البحث بالاسم أو التصنيف أو الباركود
        _filteredProducts = _allProducts.where((product) {
          final name = product['name'].toString().toLowerCase();
          final category = product['category'].toString().toLowerCase();
          final barcode = product['barcode'].toString().toLowerCase();
          return name.contains(query) || category.contains(query) || barcode.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // لون شريط الحالة للمنتج
  Color _getStatusColor(String status) {
    if (status == 'متوفر') return Colors.green;
    if (status == 'قارب على الانتهاء') return Colors.orange;
    return Colors.red;
  }

  Color _getStatusBgColor(String status) {
    if (status == 'متوفر') return Colors.green.shade50;
    if (status == 'قارب على الانتهاء') return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'إدارة المنتجات والمخزون',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () {
              // إضافة منتج جديد
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. حقل البحث المتقدم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'بحث عن منتج أو تصنيف...',
                suffixIcon: const Icon(Icons.search, color: Color(0xFF0277BD)),
                prefixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                fillColor: const Color(0xFFF0F4F8),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. زر كشف حركة مادة (مستقل)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0277BD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ItemMovementFilterScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                label: const Text(
                  'كشف حركة مادة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 3. قائمة المنتجات المفلترة
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد منتجات تطابق البحث',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1.5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            // عند الضغط على المادة الانتقال لبطاقة المادة
                            final updatedProduct = await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductCardScreen(product: product),
                              ),
                            );

                            // تحديث القائمة في حال تعديل البيانات داخل بطاقة المادة
                            if (updatedProduct != null) {
                              setState(() {
                                final prodIndex = _allProducts.indexWhere((p) => p['id'] == updatedProduct['id']);
                                if (prodIndex != -1) {
                                  _allProducts[prodIndex] = updatedProduct;
                                  _onSearchChanged(); // إعادة تطبيق الفلترة
                                }
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // رمز المنتج
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Color(0xFF0277BD),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // تفاصيل المنتج
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'التصنيف: ${product['category']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${product['price']} ل.س',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0277BD),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // حالة المخزون
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusBgColor(product['status']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${product['status']} (${product['stock']})',
                                    style: TextStyle(
                                      color: _getStatusColor(product['status']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
