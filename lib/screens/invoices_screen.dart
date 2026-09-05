import 'package:flutter/material.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> invoices = [
      {
        'id': '#INV-1024',
        'customer': 'أحمد المحمد',
        'date': '2026-03-30',
        'total': '45,000 ل.س',
        'status': 'مدفوعة',
        'statusColor': Colors.green,
      },
      {
        'id': '#INV-1023',
        'customer': 'شركة الأمل',
        'date': '2026-03-30',
        'total': '120,000 ل.س',
        'status': 'آجل',
        'statusColor': Colors.orange,
      },
      {
        'id': '#INV-1022',
        'customer': 'محمود العلي',
        'date': '2026-03-29',
        'total': '18,500 ل.س',
        'status': 'مدفوعة',
        'statusColor': Colors.green,
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        appBar: AppBar(
          title: const Text('سجل الفواتير', style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final inv = invoices[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: const Icon(Icons.receipt, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(inv['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(inv['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('العميل: ${inv['customer']}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(inv['total'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (inv['statusColor'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                inv['status'],
                                style: TextStyle(fontSize: 11, color: inv['statusColor'], fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
