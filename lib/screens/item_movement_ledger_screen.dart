import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ItemMovementLedgerScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final int? partyId;
  final String? partyName;
  final DateTime startDate;
  final DateTime endDate;

  const ItemMovementLedgerScreen({
    super.key,
    required this.productId,
    required this.productName,
    this.partyId,
    this.partyName,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<ItemMovementLedgerScreen> createState() => _ItemMovementLedgerScreenState();
}

class _ItemMovementLedgerScreenState extends State<ItemMovementLedgerScreen> {
  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      String query = '''
        SELECT 
          ii.quantity, ii.price,
          i.type as invoice_type, i.date as invoice_date, i.id as invoice_id,
          p.name as party_name
        FROM invoice_items ii
        INNER JOIN invoices i ON ii.invoice_id = i.id
        LEFT JOIN parties p ON i.party_id = p.id
        WHERE ii.product_id = ?
      ''';

      List<dynamic> args = [widget.productId];

      if (widget.partyId != null) {
        query += ' AND i.party_id = ?';
        args.add(widget.partyId);
      }

      query += ' ORDER BY i.date DESC';

      final results = await db.rawQuery(query, args);

      setState(() {
        _movements = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حركة: ${widget.productName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movements.isEmpty
              ? const Center(child: Text('لا توجد حركات لهذه المادة ضمن الشروط المحددة'))
              : ListView.builder(
                  itemCount: _movements.length,
                  itemBuilder: (context, index) {
                    final item = _movements[index];
                    final isSale = item['invoice_type'] == 'sale' || item['invoice_type'] == 'مبيعات';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          isSale ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isSale ? Colors.red : Colors.green,
                        ),
                        title: Text('${isSale ? "مبيعات" : "مشتريات"} - فاتورة #${item['invoice_id']}'),
                        subtitle: Text('الجهة: ${item['party_name'] ?? "عام"} | التاريخ: ${item['invoice_date']}'),
                        trailing: Column(
                          mainCenter: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('الكمية: ${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('السعر: ${item['price']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
