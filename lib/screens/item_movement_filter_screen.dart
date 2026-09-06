import 'package:flutter/material.dart';

class ItemMovementFilterScreen extends StatefulWidget {
  const ItemMovementFilterScreen({super.key});

  @override
  State<ItemMovementFilterScreen> createState() => _ItemMovementFilterScreenState();
}

class _ItemMovementFilterScreenState extends State<ItemMovementFilterScreen> {
  // controllers للحقول النصية
  final _itemNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _warehouseController = TextEditingController();
  final _accountController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _representativeController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedMovementType = 'الكل';

  final List<String> _movementTypes = ['الكل', 'مبيعات', 'مشتريات', 'مرتجعات', 'تعديل مخزون'];

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          suffixIcon: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('F4', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تصفية حركة المواد'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الفترة الزمنية
              const Text('الفترة الزمنية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _fromDate == null
                            ? 'من تاريخ'
                            : '${_fromDate!.year}/${_fromDate!.month}/${_fromDate!.day}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _toDate == null
                            ? 'إلى تاريخ'
                            : '${_toDate!.year}/${_toDate!.month}/${_toDate!.day}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // نوع الحركة
              const Text('نوع الحركة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMovementType,
                items: _movementTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMovementType = val);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // الحقول التفصيلية
              const Text('خيارات البحث والتصفية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),

              _buildTextField(label: 'اسم المادة', controller: _itemNameController, icon: Icons.inventory_2_outlined),
              _buildTextField(label: 'الصنف', controller: _categoryController, icon: Icons.category_outlined),
              _buildTextField(label: 'مستودع محدد', controller: _warehouseController, icon: Icons.store_outlined),
              _buildTextField(label: 'حساب محدد (العميل/المورد)', controller: _accountController, icon: Icons.person_outline),
              _buildTextField(label: 'الباركود', controller: _barcodeController, icon: Icons.qr_code_scanner),
              _buildTextField(label: 'المندوب', controller: _representativeController, icon: Icons.badge_outlined),

              const SizedBox(height: 16),

              // زر التطبيق
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'fromDate': _fromDate,
                      'toDate': _toDate,
                      'movementType': _selectedMovementType,
                      'itemName': _itemNameController.text,
                      'category': _categoryController.text,
                      'warehouse': _warehouseController.text,
                      'account': _accountController.text,
                      'barcode': _barcodeController.text,
                      'representative': _representativeController.text,
                    });
                  },
                  child: const Text('تطبيق التصفية', style: TextStyle(fontSize: 16)),
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
    _itemNameController.dispose();
    _categoryController.dispose();
    _warehouseController.dispose();
    _accountController.dispose();
    _barcodeController.dispose();
    _representativeController.dispose();
    super.dispose();
  }
}
