import 'package:flutter/material.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        name: _nameController.text,
        barcode: _barcodeController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ المنتج: ${newProduct.name} بنجاح'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        appBar: AppBar(
          title: const Text('إضافة منتج جديد', style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'اسم المنتج',
                  icon: Icons.shopping_bag_outlined,
                  validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال اسم المنتج' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _barcodeController,
                  label: 'الباركود / رمز المنتج',
                  icon: Icons.qr_code_scanner,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _priceController,
                  label: 'سعر البيع',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال السعر' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _quantityController,
                  label: 'الكمية المتاحة',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال الكمية' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('حفظ المنتج', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF0284C7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
