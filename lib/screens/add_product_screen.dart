import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController(); // سعر المفرق
  final TextEditingController _semiWholesalePriceController = TextEditingController(); // سعر نصف الجملة
  final TextEditingController _wholesalePriceController = TextEditingController(); // سعر الجملة
  final TextEditingController _qtyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة منتج جديد'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الكمية الأوليّة في المخزن',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'أسعار البيع والتسعير:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 8),

              // سعر المفرق
              TextField(
                controller: _retailPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر المفرق (ل.س)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // سعر نصف الجملة
              TextField(
                controller: _semiWholesalePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر نصف الجملة (ل.س)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // سعر الجملة
              TextField(
                controller: _wholesalePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر الجملة (ل.س)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warehouse_outlined),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
                  onPressed: () {
                    // حفظ المنتج وحفظ الأسعار الثلاثة في قاعدة البيانات لاحقاً
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ المنتج', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _retailPriceController.dispose();
    _semiWholesalePriceController.dispose();
    _wholesalePriceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }
}
