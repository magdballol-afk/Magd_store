import 'package:flutter/material.dart';

class ItemMovementFilterScreen extends StatefulWidget {
  const ItemMovementFilterScreen({super.key});

  @override
  State<ItemMovementFilterScreen> createState() => _ItemMovementFilterScreenState();
}

class _ItemMovementFilterScreenState extends State<ItemMovementFilterScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تصفية حركة المواد'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نوع الحركة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMovementType,
                items: _movementTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMovementType = val);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'الفترة الزمنية:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _fromDate == null
                            ? 'من تاريخ'
                            : '${_fromDate!.year}-${_fromDate!.month}-${_fromDate!.day}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _toDate == null
                            ? 'إلى تاريخ'
                            : '${_toDate!.year}-${_toDate!.month}-${_toDate!.day}',
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'type': _selectedMovementType,
                      'fromDate': _fromDate,
                      'toDate': _toDate,
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
}
