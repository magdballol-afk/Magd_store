import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class ProductCardScreen extends StatefulWidget {
  final Product product;

  const ProductCardScreen({super.key, required this.product});

  @override
  State<ProductCardScreen> createState() => _ProductCardScreenState();
}

class _ProductCardScreenState extends State<ProductCardScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _buyPriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _buyPriceController = TextEditingController(text: widget.product.buyPrice.toString());
    _wholesalePriceController = TextEditingController(text: widget.product.wholesalePrice.toString());
    _retailPriceController = TextEditingController(text: widget.product.retailPrice.toString());
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text.trim(),
      buyPrice: double.tryParse(_buyPriceController.text) ?? widget.product.buyPrice,
      wholesalePrice: double.tryParse(_wholesalePriceController.text) ?? widget.product.wholesalePrice,
      retailPrice: double.tryParse(_retailPriceController.text) ?? widget.product.retailPrice,
      stockQuantity: double.tryParse(_stockController.text) ?? widget.product.stockQuantity,
    );

    await DatabaseHelper.instance.updateProduct(updatedProduct);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
      );
      Navigator.pop(context, true);
    }
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
                            'معرف المادة: ${widget.product.id ?? "جديد"}',
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
              label: 'سعر الشراء:',
              controller: _buyPriceController,
              icon: Icons.shopping_bag_outlined,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'سعر الجملة:',
              controller: _wholesalePriceController,
              icon: Icons.storefront_outlined,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'سعر المفرق:',
              controller: _retailPriceController,
              icon: Icons.sell_outlined,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'الكمية المتاحة في المخزون:',
              controller: _stockController,
              icon: Icons.storage_outlined,
              keyboardType: TextInputType.number,
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
