import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'item_movement_ledger_screen.dart';

class ItemMovementFilterScreen extends StatefulWidget {
  const ItemMovementFilterScreen({super.key});

  @override
  State<ItemMovementFilterScreen> createState() => _ItemMovementFilterScreenState();
}

class _ItemMovementFilterScreenState extends State<ItemMovementFilterScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _parties = [];

  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedParty;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // جلب المواد والجهات (عملاء وموردين) من قاعدة البيانات
  Future<void> _loadInitialData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final prods = await db.query('products', orderBy: 'name ASC');
      
      // التعديل هنا: جلب البيانات من جدول contacts المعتمد في DatabaseHelper
      final parts = await db.query('contacts', orderBy: 'name ASC');

      setState(() {
        _products = prods;
        _parties = parts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ أثناء تحميل البيانات: $e');
      setState(() => _isLoading = false);
    }
  }

  // الانتقال إلى كشف الحركة بالتفاصيل
  void _submitFilter() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار المادة أولاً لعرض حركة كشف الحساب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemMovementLedgerScreen(
          productId: int.tryParse(_selectedProduct!['id']?.toString() ?? '') ?? 0,
          productName: _selectedProduct!['name']?.toString() ?? '',
          partyId: _selectedParty != null 
              ? int.tryParse(_selectedParty!['id']?.toString() ?? '') 
              : null,
          partyName: _selectedParty?['name']?.toString(),
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فلترة كشف حركة مادة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حدد المادة والمعايير المطلوبة لعرض الكشف التفصيلي:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 1. اختيار المادة (مطلوب)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'اختر المادة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    items: _products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p['name']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedProduct = val),
                  ),
                  const SizedBox(height: 16),

                  // 2. اختيار العميل / المورد (اختياري)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedParty,
                    decoration: const InputDecoration(
                      labelText: 'الحساب المرتبط (عميل/مورد) - اختياري',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: [
                      const DropdownMenuItem<Map<String, dynamic>>(
                        value: null,
                        child: Text('جميع الحسابات (كافة العملاء والموردين)'),
                      ),
                      ..._parties.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(p['name']?.toString() ?? ''),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedParty = val),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'الفترة الزمنية:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // 3. تحديد التاريخ (من - إلى)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text('من: ${_startDate.toIso8601String().split('T').first}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _startDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text('إلى: ${_endDate.toIso8601String().split('T').first}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _endDate = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // زر تنفيذ العرض
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text(
                        'عرض كشف الحركة',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _submitFilter,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
