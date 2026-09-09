import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController(); // حقل سعر الشراء الجديد
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _halfWholesalePriceController = TextEditingController();
  final TextEditingController _wholesalePriceController = TextEditingController();

  String? _selectedCategory;

  final List<String> _categories = [
    'العناية الشخصية',
    'منظفات',
    'ورقيات',
    'مواد غذائية',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _retailPriceController.dispose();
    _halfWholesalePriceController.dispose();
    _wholesalePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'إضافة منتج جديد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. اسم المنتج
                _buildInputField(
                  controller: _nameController,
                  hintText: 'اسم المنتج',
                  icon: Icons.shopping_bag_outlined,
                ),
                const SizedBox(height: 12),

                // 2. اختر الصنف
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _inputDecoration(
                    hintText: 'اختر الصنف',
                    icon: Icons.category_outlined,
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (val) => val == null ? 'يرجى اختيار الصنف' : null,
                ),
                const SizedBox(height: 12),

                // 3. الكمية الأولية في المخزن
                _buildInputField(
                  controller: _quantityController,
                  hintText: 'الكمية الأولية في المخزن',
                  icon: Icons.archive_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // عنوان أسعار البيع والتسعير
                const Text(
                  ':أسعار البيع والتسعير',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. سعر الشراء / التكلفة (الحقل المضاف)
                _buildInputField(
                  controller: _purchasePriceController,
                  hintText: 'سعر الشراء / التكلفة (ل.س)',
                  icon: Icons.shopping_cart_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                // 5. سعر المفرق
                _buildInputField(
                  controller: _retailPriceController,
                  hintText: 'سعر المفرق (ل.س)',
                  icon: Icons.label_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                // 6. سعر نصف الجملة
                _buildInputField(
                  controller: _halfWholesalePriceController,
                  hintText: 'سعر نصف الجملة (ل.س)',
                  icon: Icons.store_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                // 7. سعر الجملة
                _buildInputField(
                  controller: _wholesalePriceController,
                  hintText: 'سعر الجملة (ل.س)',
                  icon: Icons.location_city_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 28),

                // زر حفظ المنتج
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    label: const Text(
                      'حفظ المنتج',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hintText: hintText, icon: icon),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade700),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text;
      final double purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;

      // أضف منطق الحفظ الخاص بـ Database / State Management هنا
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ المنتج: $name بسعر تكلفة $purchasePrice ل.س')),
      );
    }
  }
}
