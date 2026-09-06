import 'package:flutter/material.dart';
import 'item_movement_ledger_screen.dart';

class ItemMovementFilterScreen extends StatefulWidget {
  const ItemMovementFilterScreen({Key? key}) : super(key: key);

  @override
  State<ItemMovementFilterScreen> createState() => _ItemMovementFilterScreenState();
}

class _ItemMovementFilterScreenState extends State<ItemMovementFilterScreen> {
  final TextEditingController _itemController = TextEditingController(text: 'شاي ليالينا 100غ');
  final TextEditingController _fromDateController = TextEditingController(text: '2025/01/01');
  final TextEditingController _toDateController = TextEditingController(text: '2026/09/06');
  final TextEditingController _warehouseController = TextEditingController(text: 'المستودع 1');
  final TextEditingController _accountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text('خيارات كشف حركة مادة'),
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildFilterRow('من تاريخ', _fromDateController, isDate: true),
            _buildFilterRow('إلى تاريخ', _toDateController, isDate: true),
            _buildFilterRow('اسم المادة', _itemController),
            _buildFilterRow('الصنف', TextEditingController()),
            _buildFilterRow('مستودع محدد', _warehouseController),
            _buildFilterRow('حساب محدد', _accountController),
            _buildFilterRow('الرقم التسلسلي', TextEditingController()),
            _buildFilterRow('الباركود', TextEditingController()),
            _buildFilterRow('المشروع', TextEditingController()),
            _buildFilterRow('المندوب', TextEditingController()),
            const SizedBox(height: 20),

            // زر موافق لعرض كشف الحركة
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0277BD),
                      padding: const EdgeInsets.vertical(12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemMovementLedgerScreen(
                            itemName: _itemController.text,
                            fromDate: _fromDateController.text,
                            toDate: _toDateController.text,
                          ),
                        ),
                      );
                    },
                    child: const Text('موافق / عرض', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.vertical(12)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String label, TextEditingController controller, {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 38,
              color: Colors.white,
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: const OutlineInputBorder(),
                  suffixIcon: isDate ? const Icon(Icons.calendar_today, size: 16) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
