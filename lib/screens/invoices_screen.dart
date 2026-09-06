import 'package:flutter/material.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  // قائمة وهمية للفواتير لتوضيح آلية الفلترة
  final List<Map<String, dynamic>> _allInvoices = [
    {
      'id': 'INV-1024#',
      'client': 'أحمد المحمد',
      'amount': '45,000 ل.س',
      'date': DateTime(2026, 3, 30),
      'type': 'مبيعات',
      'status': 'مدفوعة',
    },
    {
      'id': 'INV-1023#',
      'client': 'شركة الأمل',
      'amount': '120,000 ل.س',
      'date': DateTime(2026, 3, 30),
      'type': 'مبيعات',
      'status': 'آجل',
    },
    {
      'id': 'PUR-2001#',
      'client': 'مورد المواد الأولية',
      'amount': '350,000 ل.س',
      'date': DateTime(2026, 3, 29),
      'type': 'مشتريات',
      'status': 'مدفوعة',
    },
    {
      'id': 'INV-1022#',
      'client': 'محمود العلي',
      'amount': '18,500 ل.س',
      'date': DateTime(2026, 3, 29),
      'type': 'مبيعات',
      'status': 'مدفوعة',
    },
  ];

  // دالة اختيار التاريخ
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  // تصفية الفواتير بناءً على النوع والتاريخ
  List<Map<String, dynamic>> _getFilteredInvoices(String type) {
    return _allInvoices.where((inv) {
      final bool matchesType = inv['type'] == type;
      bool matchesDate = true;

      if (_fromDate != null && _toDate != null) {
        final DateTime invDate = inv['date'];
        matchesDate = invDate.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
                      invDate.isBefore(_toDate!.add(const Duration(days: 1)));
      }

      return matchesType && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('سجل الفواتير'),
            backgroundColor: const Color(0xFF0D47A1),
            actions: [
              // زر الفلترة بالتاريخ
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                tooltip: 'تصفية بالتاريخ',
                onPressed: () => _selectDateRange(context),
              ),
              if (_fromDate != null)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'إلغاء التصفية',
                  onPressed: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                    });
                  },
                ),
            ],
            bottom: const TabBar(
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'فواتير المبيعات'),
                Tab(text: 'فواتير المشتريات'),
              ],
            ),
          ),
          body: Column(
            children: [
              // شريط توضيحي في حال تطبيق فلترة التاريخ
              if (_fromDate != null && _toDate != null)
                Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الفترة: ${_fromDate!.year}/${_fromDate!.month}/${_fromDate!.day} - ${_toDate!.year}/${_toDate!.month}/${_toDate!.day}',
                        style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                          });
                        },
                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                      )
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInvoicesList(_getFilteredInvoices('مبيعات')),
                    _buildInvoicesList(_getFilteredInvoices('مشتريات')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بناء قائمة الفواتير
  Widget _buildInvoicesList(List<Map<String, dynamic>> invoices) {
    if (invoices.isEmpty) {
      return const Center(
        child: Text('لا توجد فواتير مطابقة للبحث', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final item = invoices[index];
        final bool isPaid = item['status'] == 'مدفوعة';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item['date'].year}-${item['date'].month.toString().padLeft(2, '0')}-${item['date'].day.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            item['id'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item['type'] == 'مبيعات' ? 'العميل' : 'المورد'}: ${item['client']}',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['status'],
                              style: TextStyle(
                                color: isPaid ? Colors.green : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            item['amount'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt, color: Color(0xFF0D47A1)),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
