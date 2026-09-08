import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // المتحكمات بالحقول النصية
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _halfWholesalePriceController = TextEditingController();
  final TextEditingController _wholesalePriceController = TextEditingController();

  // متغير وحقول الصنف
  String? _selectedCategory;
  final List<String> _categories = [
    'مواد غذائية',
    'منظفات',
    'أجهزة إلكترونية',
    'ألبسة',
    'عام',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _retailPriceController.dispose();
    _halfWholesalePriceController.dispose();
    _wholesalePriceController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      // تم التحقق بنجاح، تجهيز البيانات للحفظ
      final String productName = _nameController.text;
      final String category = _selectedCategory!;
      final double quantity = double.tryParse(_quantityController.text) ?? 0.0;
      final double retailPrice = double.tryParse(_retailPriceController.text) ?? 0.0;
      final double halfWholesalePrice = double.tryParse(_halfWholesalePriceController.text) ?? 0.0;
      final double wholesalePrice = double.tryParse(_wholesalePriceController.text) ?? 0.0;

      // TODO: قم باستدعاء دالة الحفظ في قاعدة البيانات هنا
      print('إرسال لقاعدة البيانات: $productName - $category');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المنتج بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1), // اللون الأزرق من تصميمك
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. اسم المنتج
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('اسم المنتج', Icons.shopping_bag_outlined),
                validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال اسم المنتج' : null,
              ),
              const SizedBox(height: 12.0),

              // 2. حقل الصنف (المضاف حديثاً)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _buildInputDecoration('اختر الصنف', Icons.category_outlined),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) => value == null ? 'يرجى اختيار الصنف' : null,
              ),
              const SizedBox(height: 12.0),

              // 3. الكمية الأولية في المخزن
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('الكمية الأولية في المخزن', Icons.inventory_2_outlined),
              ),
              const SizedBox(height: 20.0),

              // عنوان أسعار البيع والتسعير
              const Text(
                'أسعار البيع والتسعير:',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12.0),

              // 4. سعر المفرق
              TextFormField(
                controller: _retailPriceController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('سعر المفرق (ل.س)', Icons.local_offer_outlined),
              ),
              const SizedBox(height: 12.0),

              // 5. سعر نصف الجملة
              TextFormField(
                controller: _halfWholesalePriceController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('سعر نصف الجملة (ل.س)', Icons.storefront_outlined),
              ),
              const SizedBox(height: 12.0),

              // 6. سعر الجملة
              TextFormField(
                controller: _wholesalePriceController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('سعر الجملة (ل.س)', Icons.home_work_outlined),
              ),
              const SizedBox(height: 24.0),

              // زر حفظ المنتج
              ElevatedButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ المنتج', style: TextStyle(fontSize: 18.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لتطبيق تصميم الحقول الموحد
  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.grey[700]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2.0),
      ),
    );
  }
}
