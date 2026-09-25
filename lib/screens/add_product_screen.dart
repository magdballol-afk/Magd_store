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
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _wholesalePriceController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String name = _nameController.text.trim();
      final double buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0.0;
      final double wholesalePrice = double.tryParse(_wholesalePriceController.text.trim()) ?? 0.0;
      final double retailPrice = double.tryParse(_retailPriceController.text.trim()) ?? 0.0;
      final double quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;

      // إرسال الخريطة بأسماء الأعمدة المطابقة لقاعدة البيانات بالضبط
      final Map<String, dynamic> productRow = {
        'name': name,
        'buy_price': buyPrice,
        'wholesale_price': wholesalePrice,
        'retail_price': retailPrice,
        'stock_quantity': quantity,
        'price': retailPrice,     // حقل احتياطي للتوافق
        'quantity': quantity,     // حقل احتياطي للتوافق
      };

      await DatabaseHelper.instance.insertProduct(productRow);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المادة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyPriceController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text(
          'إضافة منتج جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
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
                    labelText: 'اسم المادة',
                    prefixIcon: Icon(Icons.label_outline, color: Color(0xFF0277BD)),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المادة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _buyPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر الشراء',
                    prefixIcon: Icon(Icons.shopping_bag_outlined, color: Color(0xFF0277BD)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _wholesalePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر الجملة',
                    prefixIcon: Icon(Icons.storefront_outlined, color: Color(0xFF0277BD)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _retailPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'سعر المفرق',
                    prefixIcon: Icon(Icons.sell_outlined, color: Color(0xFF0277BD)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الكمية الأوليّة / المتاحة في المخزون',
                    prefixIcon: Icon(Icons.storage_outlined, color: Color(0xFF0277BD)),
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
                      backgroundColor: const Color(0xFF0277BD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveProduct,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'حفظ المنتج',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
}
