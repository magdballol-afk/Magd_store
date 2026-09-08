import 'package:flutter/material.dart';
import 'item_movement_filter_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      ),
      body: Column(
        children: [
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
                        onPressed: () => _searchController.clear(),
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
                            final updatedProduct = await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductCardScreen(product: product),
                              ),
                            );

                            if (updatedProduct != null) {
                              setState(() {
                                final prodIndex = _allProducts.indexWhere((p) => p['id'] == updatedProduct['id']);
                                if (prodIndex != -1) {
                                  _allProducts[prodIndex] = updatedProduct;
                                  _onSearchChanged();
                                }
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
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

class ProductCardScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductCardScreen({super.key, required this.product});

  @override
  State<ProductCardScreen> createState() => _ProductCardScreenState();
}

class _ProductCardScreenState extends State<ProductCardScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _barcodeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _categoryController = TextEditingController(text: widget.product['category']);
    _priceController = TextEditingController(text: widget.product['price'].toString());
    _stockController = TextEditingController(text: widget.product['stock'].toString());
    _barcodeController = TextEditingController(text: widget.product['barcode'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedData = {
      'id': widget.product['id'],
      'name': _nameController.text,
      'category': _categoryController.text,
      'price': double.tryParse(_priceController.text) ?? widget.product['price'],
      'stock': int.tryParse(_stockController.text) ?? widget.product['stock'],
      'status': (int.tryParse(_stockController.text) ?? 0) > 10
          ? 'متوفر'
          : ((int.tryParse(_stockController.text) ?? 0) > 0 ? 'قارب على الانتهاء' : 'نفذت الكمية'),
      'barcode': _barcodeController.text,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
    );

    Navigator.pop(context, updatedData);
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: _isEditing,
            keyboardType: keyboardType,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF0277BD)),
              fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
        title: const Text(
          'بطاقة المادة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFE1F5FE),
                      child: Icon(Icons.inventory, color: Color(0xFF0277BD), size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'معرف المادة: ${widget.product['id']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              label: 'اسم المادة:',
              controller: _nameController,
              icon: Icons.label_outline,
            ),
            _buildField(
              label: 'الصنف / التصنيف:',
              controller: _categoryController,
              icon: Icons.category_outlined,
            ),
            _buildField(
              label: 'السعر (ل.س):',
              controller: _priceController,
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'الكمية المتاحة في المخزون:',
              controller: _stockController,
              icon: Icons.storage_outlined,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'الباركود:',
              controller: _barcodeController,
              icon: Icons.qr_code,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.green : const Color(0xFF0277BD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  if (_isEditing) {
                    _saveChanges();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
                icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                label: Text(
                  _isEditing ? 'حفظ التعديلات' : 'تعديل البطاقة',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
