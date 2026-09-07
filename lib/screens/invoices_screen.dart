import 'package:flutter/material.dart';
import 'new_invoice_screen.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  // قائمة فواتير تجريبية مطابقة للصورة الثانية
  final List<Map<String, dynamic>> invoices = const [
    {
      'id': 'INV-1024#',
      'customer': 'أحمد المحمد',
      'date': '2026-03-30',
      'amount': '45,000',
      'status': 'مدفوعة',
      'type': 'مبيعات',
      'paymentType': 'نقدي',
      'items': [
        {'name': 'شامبو بانتين 400 مل', 'price': 15000.0, 'quantity': 3, 'discount': 0.0}
      ]
    },
    {
      'id': 'INV-1023#',
      'customer': 'شركة الأمل',
      'date': '2026-03-30',
      'amount': '120,000',
      'status': 'آجل',
      'type': 'مبيعات',
      'paymentType': 'آجل (دين)',
      'items': [
        {'name': 'معجون أسنان كولجيت', 'price': 8000.0, 'quantity': 10, 'discount': 0.0},
        {'name': 'مناديل فاين 500 منديل', 'price': 10000.0, 'quantity': 4, 'discount': 0.0}
      ]
    },
    {
      'id': 'INV-1022#',
      'customer': 'محمود العلي',
      'date': '2026-03-29',
      'amount': '18,500',
      'status': 'مدفوعة',
      'type': 'مبيعات',
      'paymentType': 'نقدي',
      'items': [
        {'name': 'صابون دوف 100غ', 'price': 4500.0, 'quantity': 3, 'discount': 0.0}
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0277BD),
          title: const Text('سجل الفواتير', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'فواتير المبيعات'),
              Tab(text: 'فواتير المشتريات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInvoiceList(context, 'مبيعات'),
            _buildInvoiceList(context, 'مشتريات'),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, String type) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final inv = invoices[index];
        final bool isPaid = inv['status'] == 'مدفوعة';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.receipt, color: Color(0xFF0277BD)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(inv['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(inv['date'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('العميل: ${inv['customer']}'),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${inv['amount']} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        inv['status'],
                        style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // فتح الفاتورة الأصلية وتمرير بياناتها للعرض والتعديل
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewInvoiceScreen(existingInvoice: inv),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
