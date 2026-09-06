import 'package:flutter/material.dart';

class ItemMovementLedgerScreen extends StatelessWidget {
  final String itemName;
  final String fromDate;
  final String toDate;

  ItemMovementLedgerScreen({
    Key? key,
    required this.itemName,
    required this.fromDate,
    required this.toDate,
  }) : super(key: key);

  // بيانات الحركة المطابقة للصورة الأخيرة
  final List<Map<String, dynamic>> dummyMovements = [
    {'date': '2025/01/04', 'account': 'أبو علي حبل موالح', 'invoiceNo': '113798', 'type': 'مبيع', 'qtyOut': 2, 'price': '160,000'},
    {'date': '2025/01/04', 'account': 'علاء دبوب', 'invoiceNo': '113815', 'type': 'مبيع', 'qtyOut': 2, 'price': '126,500'},
    {'date': '2025/01/05', 'account': 'معهد رشة', 'invoiceNo': '113861', 'type': 'مبيع', 'qtyOut': 1, 'price': '130,000'},
    {'date': '2025/01/05', 'account': 'أنس برو', 'invoiceNo': '113868', 'type': 'مبيع', 'qtyOut': 1, 'price': '127,000'},
    {'date': '2025/01/06', 'account': 'محمد برو', 'invoiceNo': '113904', 'type': 'مبيع', 'qtyOut': 1, 'price': '125,000'},
    {'date': '2025/01/06', 'account': 'مهند نوح', 'invoiceNo': '113923', 'type': 'مبيع', 'qtyOut': 2, 'price': '130,000'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حركة: $itemName'),
        backgroundColor: const Color(0xFF0277BD),
      ),
      body: Column(
        children: [
          // شريط النطاق الزمني العلوي
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('من: $fromDate', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('إلى: $toDate', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // الجدول الرئيسي للحركة
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade300),
                  columns: const [
                    DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('رقم الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('كمية خارجة', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: dummyMovements.map((move) {
                    return DataRow(
                      cells: [
                        DataCell(Text(move['date']), onTap: () => _openInvoiceDetails(context, move)),
                        DataCell(Text(move['account'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)), onTap: () => _openInvoiceDetails(context, move)),
                        DataCell(Text(move['invoiceNo']), onTap: () => _openInvoiceDetails(context, move)),
                        DataCell(Text(move['type']), onTap: () => _openInvoiceDetails(context, move)),
                        DataCell(Text(move['qtyOut'].toString()), onTap: () => _openInvoiceDetails(context, move)),
                        DataCell(Text('${move['price']} ل.س'), onTap: () => _openInvoiceDetails(context, move)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // الخطوة الأخيرة: التوجيه وتفاصيل الفاتورة عند النقر على الحركة
  void _openInvoiceDetails(BuildContext context, Map<String, dynamic> move) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تفاصيل الفاتورة #${move['invoiceNo']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                Chip(label: Text(move['type']), backgroundColor: Colors.blue.shade50),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('اسم الحساب / العميل: ${move['account']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text('تاريخ الحركة: ${move['date']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 6),
            Text('المادة: $itemName', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text('الكمية: ${move['qtyOut']}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text('إجمالي السعر: ${move['price']} ل.س', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0277BD)),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق / العودة للكشف', style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
