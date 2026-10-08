import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // عند التعديل نمرر المادة، وعند الإضافة نتركها null

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _buyPriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _halfWholesalePriceController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _quantityController;

  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['name']?.toString() ?? '');
    _barcodeController = TextEditingController(text: widget.product?['barcode']?.toString() ?? '');
    _buyPriceController = TextEditingController(
      text: widget.product?['buy_price'] != null ? widget.product!['buy_price'].toString() : '',
    );
    _retailPriceController = TextEditingController(
      text: widget.product?['retail_price'] != null ? widget.product!['retail_price'].toString() : '',
    );
    _halfWholesalePriceController = TextEditingController(
      text: widget.product?['half_wholesale_price'] != null ? widget.product!['half_wholesale_price'].toString() : '',
    );
    _wholesalePriceController = TextEditingController(
      text: widget.product?['wholesale_price'] != null ? widget.product!['wholesale_price'].toString() : '',
    );
    _quantityController = TextEditingController(
      text: widget.product?['quantity'] != null ? widget.product!['quantity'].toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _retailPriceController.dispose();
    _halfWholesalePriceController.dispose();
    _wholesalePriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // فتح شاشة الكاميرا لمسح الباركود
  Future<void> _scanBarcode() async {
    final scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerSimpleScreen(),
      ),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      setState(() {
        _barcodeController.text = scannedBarcode;
      });
    }
  }

  Future<void> _saveOrUpdateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'barcode': _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        'buy_price': double.tryParse(_buyPriceController.text) ?? 0.0,
        'retail_price': double.tryParse(_retailPriceController.text) ?? 0.0,
        'half_wholesale_price': double.tryParse(_halfWholesalePriceController.text) ?? 0.0,
        'wholesale_price': double.tryParse(_wholesalePriceController.text) ?? 0.0,
        'quantity': double.tryParse(_quantityController.text) ?? 0.0,
      };

      if (_isEditing) {
        productData['id'] = widget.product!['id'];
        await DatabaseHelper.instance.updateProduct(productData);
      } else {
        await DatabaseHelper.instance.insertProduct(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'تم حفظ التعديلات بنجاح' : 'تمت إضافة المادة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل منتج' : 'إضافة منتج جديد',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0277BD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'اسم المادة', Icons.inventory_2_outlined, isRequired: true),
              const SizedBox(height: 12),
              
              // حقل الباركود مع زر المسح بالكاميرا
              _buildBarcodeField(),
              const SizedBox(height: 12),

              _buildTextField(_buyPriceController, 'سعر الشراء', Icons.shopping_bag_outlined, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_retailPriceController, 'سعر المفرق', Icons.local_offer_outlined, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_halfWholesalePriceController, 'سعر نصف الجملة', Icons.storefront_outlined, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_wholesalePriceController, 'سعر الجملة', Icons.domain_outlined, isNumber: true),
              const SizedBox(height: 12),
              _buildTextField(_quantityController, 'الكمية المتاحة في المخزون', Icons.dns_outlined, isNumber: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrUpdateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0277BD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0277BD)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: _barcodeController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'رمز الباركود',
        prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF0277BD)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0277BD)),
          onPressed: _scanBarcode,
          tooltip: 'مسح الباركود بالكاميرا',
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// شاشة الكاميرا البسيطة لمسح الباركود
class BarcodeScannerSimpleScreen extends StatelessWidget {
  const BarcodeScannerSimpleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        backgroundColor: const Color(0xFF0277BD),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}
