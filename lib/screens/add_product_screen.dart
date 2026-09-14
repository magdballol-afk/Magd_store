import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // متحكمات المدخلات (TextControllers)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _halfWholesalePriceController = TextEditingController();
  final TextEditingController _wholesalePriceController = TextEditingController();

  String? _selectedCategory;
  bool _isSaving = false;

  // قائمة أصناف تجريبية (يمكن توسيعها حسب الحاجة)
  final List<String> _categories = [
    'مواد غذائية',
    'منظفات',
    'حلويات',
    'مشروبات',
    'عام',
  ];

  // دالة حفظ المنتج في قاعدة البيانات
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        'category': _selectedCategory ?? 'عام',
        'quantity': double.tryParse(_quantityController.text) ?? 0.0,
        'price_cost': double.tryParse(_costPriceController.text) ?? 0.0,
        'price_retail': double.tryParse(_retailPriceController.text) ?? 0.0,
        'price_half_wholesale': double.tryParse(_halfWholesalePriceController.text) ?? 0.0,
        'price_wholesale': double.tryParse(_wholesalePriceController.text) ?? 0.0,
      };

      // إدراج البيانات في قاعدة البيانات SQLite عبر الهيلبر
      await DatabaseHelper.instance.insertProduct(productData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ المنتج بنجاح في قاعدة البيانات'),
          backgroundColor: Colors.green,
        ),
      );

      // العودة للشاشة السابقة بعد الحفظ
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحفظ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
    _halfWholesalePriceController.dispose();
    _wholesalePriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0052CC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. اسم المنتج
              _buildInputField(
                controller: _nameController,
                label: 'اسم المنتج',
                icon: Icons.shopping_bag_outlined,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'يرجى إدخال اسم المنتج' : null,
              ),
              const SizedBox(height: 16),

              // 2. اختيار الصنف
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('اختر الصنف', Icons.category_outlined),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 16),

              // 3. الكمية الأولية في المخزن
              _buildInputField(
                controller: _quantityController,
                label: 'الكمية الأولية في المخزن',
                icon: Icons.move_to_inbox_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),

              // عنوان قسم الأسعار
              const Text(
                'أسعار البيع والتسعير:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052CC),
                ),
              ),
              const SizedBox(height: 16),

              // 4. سعر الشراء / التكلفة
              _buildInputField(
                controller: _costPriceController,
                label: 'سعر الشراء / التكلفة (ل.س)',
                icon: Icons.shopping_cart_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // 5. سعر المفرق
              _buildInputField(
                controller: _retailPriceController,
                label: 'سعر المفرق (ل.س)',
                icon: Icons.sell_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // 6. سعر نصف الجملة
              _buildInputField(
                controller: _halfWholesalePriceController,
                label: 'سعر نصف الجملة (ل.س)',
                icon: Icons.storefront_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // 7. سعر الجملة
              _buildInputField(
                controller: _wholesalePriceController,
                label: 'سعر الجملة (ل.س)',
                icon: Icons.business_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 30),

              // زر حفظ المنتج
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, color: Colors.white),
                  label: Text(
                    _isSaving ? 'جاري الحفظ...' : 'حفظ المنتج',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0052CC), width: 2),
      ),
    );
  }
}
