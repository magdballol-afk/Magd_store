import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name']?.toString() ?? '';
      _barcodeController.text = widget.product!['barcode']?.toString() ?? '';
      _buyPriceController.text = widget.product!['buy_price']?.toString() ?? '';
      _retailPriceController.text = widget.product!['retail_price']?.toString() ?? '';
      _quantityController.text = widget.product!['quantity']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _retailPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final String? scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerSimpleScreen(),
      ),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      setState(() {
        _barcodeController.text = scannedBarcode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم قراءة الباركود: $scannedBarcode'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final barcode = _barcodeController.text.trim();
      final buyPrice = double.tryParse(_buyPriceController.text.trim()) ?? 0.0;
      final retailPrice = double.tryParse(_retailPriceController.text.trim()) ?? 0.0;
      final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;

      final productData = {
        'name': name,
        'barcode': barcode,
        'buy_price': buyPrice,
        'retail_price': retailPrice,
        'quantity': quantity,
      };

      if (widget.product != null && widget.product!['id'] != null) {
        // إصلاح الخطأ الأول: تمرير المعرف داخل المخطط Data Map إذا كانت الدالة تتطلب ذلك
        final Map<String, dynamic> updateData = Map.from(productData);
        updateData['id'] = widget.product!['id'];

        await DatabaseHelper.instance.updateProduct(updateData);
      } else {
        await DatabaseHelper.instance.insertProduct(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ المادة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل مادة' : 'إضافة مادة جديدة'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المادة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال اسم المادة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'الباركود',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // إصلاح الخطأ الثاني: تعديل تنسيق IconButton.filled
                  IconButton.filled(
                    icon: const Icon(Icons.qr_code_scanner),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                    ),
                    tooltip: 'مسح الباركود بالكاميرا',
                    onPressed: _scanBarcode,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _buyPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'سعر الشراء',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _retailPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'سعر البيع',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'الكمية الأوليّة / المخزون',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0),
                  ),
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'تحديث المادة' : 'حفظ المادة',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarcodeScannerSimpleScreen extends StatefulWidget {
  const BarcodeScannerSimpleScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerSimpleScreen> createState() => _BarcodeScannerSimpleScreenState();
}

class _BarcodeScannerSimpleScreenState extends State<BarcodeScannerSimpleScreen> {
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              setState(() => _hasScanned = true);
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}
