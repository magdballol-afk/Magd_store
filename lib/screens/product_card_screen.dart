import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getProducts();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  void _showEditDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']?.toString() ?? '');
    final quantityController = TextEditingController(text: (product['quantity'] ?? 0.0).toString());
    final buyPriceController = TextEditingController(text: (product['buy_price'] ?? 0.0).toString());
    final retailPriceController = TextEditingController(text: (product['retail_price'] ?? 0.0).toString());
    final halfWholesaleController = TextEditingController(text: (product['half_wholesale_price'] ?? 0.0).toString());
    final wholesalePriceController = TextEditingController(text: (product['wholesale_price'] ?? 0.0).toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text('تعديل خصائص المادة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(nameController, 'اسم المادة', Icons.edit),
                const SizedBox(height: 10),
                _buildDialogField(quantityController, 'الكمية الحالية', Icons.dns, isNumber: true),
                const SizedBox(height: 10),
                _buildDialogField(buyPriceController, 'سعر الشراء', Icons.shopping_bag_outlined, isNumber: true),
                const SizedBox(height: 10),
                _buildDialogField(retailPriceController, 'سعر البيع (مفرق)', Icons.local_offer_outlined, isNumber: true),
                const SizedBox(height: 10),
                _buildDialogField(halfWholesaleController, 'سعر نصف الجملة', Icons.storefront_outlined, isNumber: true),
                const SizedBox(height: 10),
                _buildDialogField(wholesalePriceController, 'سعر الجملة', Icons.domain_outlined, isNumber: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6BC0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final updatedProduct = {
                  'id': product['id'],
                  'name': nameController.text.trim(),
                  'quantity': double.tryParse(quantityController.text) ?? 0.0,
                  'buy_price': double.tryParse(buyPriceController.text) ?? 0.0,
                  'retail_price': double.tryParse(retailPriceController.text) ?? 0.0,
                  'half_wholesale_price': double.tryParse(halfWholesaleController.text) ?? 0.0,
                  'wholesale_price': double.tryParse(wholesalePriceController.text) ?? 0.0,
                };

                await DatabaseHelper.instance.updateProduct(updatedProduct);
                Navigator.pop(context);
                _refreshProducts();
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5C6BC0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('إدارة المنتجات والمواد'),
        backgroundColor: const Color(0xFF0277BD),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('لا توجد مواد مضافة'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الكمية: ${item['quantity']} | شراء: ${item['buy_price']} | مفرق: ${item['retail_price']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF5C6BC0)),
                          onPressed: () => _showEditDialog(item),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
