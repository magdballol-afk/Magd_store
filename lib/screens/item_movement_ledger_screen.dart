import 'package:flutter/material.dart';
import 'new_invoice_screen.dart';

class ItemMovementLedgerScreen extends StatefulWidget {
  final String? itemName;
  final String? accountName;
  final String? movementType;
  final DateTime? startDate;
  final DateTime? endDate;

  const ItemMovementLedgerScreen({
    super.key,
    this.itemName,
    this.accountName,
    this.movementType,
    this.startDate,
    this.endDate,
  });

  @override
  State<ItemMovementLedgerScreen> createState() => _ItemMovementLedgerScreenState();
}

class _ItemMovementLedgerScreenState extends State<ItemMovementLedgerScreen> {
  // بيانات وهمية تمثل حركة المواد في قاعدة البيانات
  final List<Map<String, dynamic>> _allMovements = [
    {
      'id': 'INV-1001',
      'date': '2026-09-01',
      'itemName': 'شامبو بانتين 400 مل',
      'accountName': 'شركة الأمل للتجارة',
      'type': 'مشتريات (وارد)',
      'isSales': false,
      'isCash': true,
      'quantity': 50,
      'price': 10000.0,
      'total': 500000.0,
      'dealType': 'جملة',
      'items': [
        {'name': 'شامبو بانتين 400 مل', 'price': 10000.0, 'quantity': 50}
      ]
    },
    {
      'id': 'INV-1002',
      'date': '2026-09-03',
      'itemName': 'شامبو بانتين 400 مل',
      'accountName': 'سوبرماركت البركة',
      'type': 'مبيعات (صادر)',
      'isSales': true,
      'isCash': false,
      'quantity': 5,
      'price': 12500.0,
      'total': 62500.0,
      'dealType': 'مفرق',
      'items': [
        {'name': 'شامبو بانتين 400 مل', 'price': 12500.0, 'quantity': 5}
      ]
    },
    {
      'id': 'INV-1003',
      'date': '2026-09-05',
      'itemName': 'معجون أسنان كولجيت',
      'accountName': 'محل الفرح',
      'type': 'مبيعات (صادر)',
      'isSales': true,
      'isCash': true,
      'quantity': 10,
      'price': 8000.0,
      'total': 80000.0,
      'dealType': 'مفرق',
      'items': [
        {'name': 'معجون أسنان كولجيت', 'price': 8000.0, 'quantity': 10}
      ]
    },
  ];

  List<Map<String, dynamic>> _filteredMovements = [];

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    _filteredMovements = _allMovements.where((item) {
      // تصفية حسب اسم المادة
      if (widget.itemName != null && widget.itemName!.trim().isNotEmpty) {
        if (!item['itemName'].toString().contains(widget.itemName!.trim())) {
          return false;
        }
      }
      // تصفية حسب اسم الحساب
      if (widget.accountName != null && widget.accountName!.trim().isNotEmpty) {
        if (!item['accountName'].toString().contains(widget.accountName!.trim())) {
          return false;
        }
      }
      // تصفية حسب نوع الحركة
      if (widget.movementType != null && widget.movementType != 'الكل') {
        if (widget.movementType == 'مبيعات' && !item['isSales']) return false;
        if (widget.movementType == 'مشتريات' && item['isSales']) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
        title: const Text(
          'كشف حركة مادة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // شريط ملخص الفلترة
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFE1F5FE),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: Color(0xFF0277BD)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'المادة: ${widget.itemName?.isNotEmpty == true ? widget.itemName : 'الكل'} | الحساب: ${widget.accountName?.isNotEmpty == true ? widget.accountName : 'الكل'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _filteredMovements.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد حركات تطابق خيارات التصفية الحالية',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _filteredMovements.length,
                    itemBuilder: (context, index) {
                      final movement = _filteredMovements[index];
                      final isSales = movement['isSales'] as bool;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isSales ? Colors.red.shade100 : Colors.green.shade100,
                            child: Icon(
                              isSales ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isSales ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                movement['itemName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                movement['id'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('الحساب: ${movement['accountName']}'),
                              Text('النوع: ${movement['type']} | التاريخ: ${movement['date']}'),
                              Text(
                                'الكمية: ${movement['quantity']} | السعر: ${movement['price']} ل.س',
                                style: const TextStyle(color: Color(0xFF0277BD), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // الانتقال المباشر إلى الشاشة الخاصة بالفاتورة
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewInvoiceScreen(
                                  existingInvoice: {
                                    'id': movement['id'],
                                    'customerName': movement['accountName'],
                                    'isSales': movement['isSales'],
                                    'isCash': movement['isCash'],
                                    'dealType': movement['dealType'],
                                    'paidAmount': movement['total'],
                                    'items': movement['items'],
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

