import 'package:flutter/material.dart';

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
            // بطاقة رأسية توضح رمز المادة وحالتها
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

            // حقول بيانات المادة
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

            // زر الحفظ أو التعديل
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
