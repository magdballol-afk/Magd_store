import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String name = _nameController.text.trim();
    final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    // تحويل الكمية إلى double بشكل صريح لمنع خطأ Buid (type int can't be assigned to double?)
    final double quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;

    final Map<String, dynamic> productData = {
      'name': name,
      'price': price,
      'quantity': quantity,
    };

    await DatabaseHelper.instance.insertProduct(productData);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المنتج بنجاح')),
      );
      Navigator.of(context).pop(true); // العودة للشاشة السابقة مع إشارة بتحديث القائمة
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المنتج';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال السعر';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'يرجى إدخال رقم صحيح للسعر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الكمية الأوليّة / المتاحة',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال الكمية';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'يرجى إدخال رقم صحيح للكمية';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                    ),
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'حفظ المنتج',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
