import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // المتحكمات بالنصوص لجلب القيمة المدخلة من المستخدم
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // لون الخلفية الفاتح
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD), // لون شريط العنوان الأرزق
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // 1. حقل اسم المنتج
            _buildCustomTextField(
              controller: _nameController,
              hintText: 'اسم المنتج',
              icon: Icons.shopping_bag_outlined,
            ),
            const SizedBox(height: 16),

            // 2. حقل الباركود / رمز المنتج
            _buildCustomTextField(
              controller: _barcodeController,
              hintText: 'الباركود / رمز المنتج',
              icon: Icons.qr_code_scanner,
            ),
            const SizedBox(height: 16),

            // 3. حقل سعر الشراء (الحقل المضاف حديثاً)
            _buildCustomTextField(
              controller: _purchasePriceController,
              hintText: 'سعر الشراء',
              icon: Icons.shopping_cart_checkout_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 4. حقل سعر البيع
            _buildCustomTextField(
              controller: _salePriceController,
              hintText: 'سعر البيع',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 5. حقل الكمية المتاحة
            _buildCustomTextField(
              controller: _quantityController,
              hintText: 'الكمية المتاحة',
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // زر حفظ المنتج
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // هنا يتم استدعاء دالة الحفظ
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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
    );
  }

  // ودجت مخصصة لبناء حقول المدخلات بالشكل الدائري والأيقونات الموحدة
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right, // ضبط محاذاة النص لليمين
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 15,
          ),
          suffixIcon: Icon(icon, color: const Color(0xFF0277BD)), // الأيقونة جهة اليمين
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
