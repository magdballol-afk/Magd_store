import 'package:flutter/material.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';

  // قائمة تجريبية للمنتجات والمخزون
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'شامبو بانتين 400 مل',
      'category': 'العناية الشخصية',
      'price': '12,500 ل.س',
      'quantity': 45,
      'status': 'متوفر',
      'statusColor': Colors.green,
    },
    {
      'name': 'معجون أسنان كولجيت',
      'category': 'العناية الشخصية',
      'price': '8,000 ل.س',
      'quantity': 3,
      'status': 'قارب على الانتهاء',
      'statusColor': Colors.orange,
    },
    {
      'name': 'صابون دوف 100غ',
      'category': 'منظفات',
      'price': '4,500 ل.س',
      'quantity': 120,
      'status': 'متوفر',
      'statusColor': Colors.green,
    },
    {
      'name': 'مناديل فاين 500 منديل',
      'category': 'ورقيات',
      'price': '15,000 ل.س',
      'quantity': 0,
      'status': 'نفذت الكمية',
      'statusColor': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _products.where((p) {
      return p['name'].toString().contains(_searchQuery) ||
          p['category'].toString().contains(_searchQuery);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        appBar: AppBar(
          title: const Text('إدارة المنتجات والمخزون', style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductScreen()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث والفلترة
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج أو تصنيف...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0284C7)),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // قائمة المنتجات
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('لا توجد منتجات مطابقة'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFE0F2FE),
                                child: const Icon(Icons.inventory_2, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'التصنيف: ${product['category']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          product['price'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (product['statusColor'] as Color).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${product['status']} (${product['quantity']})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: product['statusColor'],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductScreen()),
            );
          },
          backgroundColor: const Color(0xFF0284C7),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('منتج جديد', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
