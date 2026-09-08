import 'package:flutter/material.dart';
import 'item_movement_ledger_screen.dart';

class ItemMovementFilterScreen extends StatefulWidget {
  const ItemMovementFilterScreen({super.key});

  @override
  State<ItemMovementFilterScreen> createState() => _ItemMovementFilterScreenState();
}

class _ItemMovementFilterScreenState extends State<ItemMovementFilterScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  String _selectedMovementType = 'الكل';
  final List<String> _movementTypes = ['الكل', 'مبيعات', 'مشتريات'];

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _delegateController = TextEditingController();

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildFilterTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: IconButton(
            icon: const Text(
              'F4',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            onPressed: () {},
          ),
          suffixIcon: Icon(icon, color: const Color(0xFF0277BD)),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 0.8),
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
    _delegateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
        title: const Text(
          'تصفية حركة المواد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // قسم الفترة الزمنية
            const Text(
              'الفترة الزمنية:',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF0277BD)),
                    label: Text(
                      _endDate == null
                          ? 'إلى تاريخ'
                          : '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF0277BD)),
                    label: Text(
                      _startDate == null
                          ? 'من تاريخ'
                          : '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // قسم نوع الحركة
            const Text(
              'نوع الحركة:',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMovementType,
                  isExpanded: true,
                  alignment: Alignment.centerRight,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMovementType = newValue;
                      });
                    }
                  },
                  items: _movementTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, textAlign: TextAlign.right),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // خيارات البحث والتصفية
            const Text(
              'خيارات البحث والتصفية:',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildFilterTextField(
              controller: _itemNameController,
              hintText: 'اسم المادة',
              icon: Icons.inventory_2_outlined,
            ),
            _buildFilterTextField(
              controller: _categoryController,
              hintText: 'الصنف',
              icon: Icons.category_outlined,
            ),
            _buildFilterTextField(
              controller: _warehouseController,
              hintText: 'مستودع محدد',
              icon: Icons.store_mall_directory_outlined,
            ),
            _buildFilterTextField(
              controller: _accountController,
              hintText: 'حساب محدد (العميل/المورد)',
              icon: Icons.person_outline,
            ),
            _buildFilterTextField(
              controller: _barcodeController,
              hintText: 'الباركود',
              icon: Icons.qr_code_scanner,
            ),
            _buildFilterTextField(
              controller: _delegateController,
              hintText: 'المندوب',
              icon: Icons.badge_outlined,
            ),

            const SizedBox(height: 20),

            // زر تطبيق التصفية
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0277BD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemMovementLedgerScreen(
                        itemName: _itemNameController.text,
                        accountName: _accountController.text,
                        movementType: _selectedMovementType,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'تطبيق التصفية',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
