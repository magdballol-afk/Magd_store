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

  double _totalInQuantity = 0.0;
  double _totalOutQuantity = 0.0;
  double _totalInValue = 0.0;
  double _totalOutValue = 0.0;

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

      double inQty = 0.0;
      double outQty = 0.0;
      double inVal = 0.0;
      double outVal = 0.0;

      for (var item in results) {
        double qty = (item['quantity'] ?? 0.0).toDouble();
        double price = (item['price'] ?? 0.0).toDouble();
        String type = (item['invoice_type'] ?? '').toString();

        bool isSale = type == 'sale' || type == 'مبيعات';

        if (isSale) {
          outQty += qty;
          outVal += (qty * price);
        } else {
          inQty += qty;
          inVal += (qty * price);
        }
      }

      setState(() {
        _movements = results;
        _totalInQuantity = inQty;
        _totalOutQuantity = outQty;
        _totalInValue = inVal;
        _totalOutValue = outVal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSummaryHeader() {
    double netQty = _totalInQuantity - _totalOutQuantity;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المادة: ${widget.productName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (widget.partyName != null)
                  Text(
                    'الجهة: ${widget.partyName}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('الوارد (مشتريات)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$_totalInQuantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text('الصادر (مبيعات)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$_totalOutQuantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text('صافي الحركة', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$netQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('كشف حركة: ${widget.productName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryHeader(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('سجل الحركات التفصيلي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                Expanded(
                  child: _movements.isEmpty
                      ? const Center(child: Text('لا توجد حركات مسجلة لهذه المادة وفقاً للشرط المنسق'))
                      : ListView.builder(
                          itemCount: _movements.length,
                          itemBuilder: (context, index) {
                            final item = _movements[index];
                            final String type = (item['invoice_type'] ?? '').toString();
                            final bool isSale = type == 'sale' || type == 'مبيعات';
                            final double qty = (item['quantity'] ?? 0.0).toDouble();
                            final double price = (item['price'] ?? 0.0).toDouble();
                            final double total = qty * price;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSale ? Colors.red.shade100 : Colors.green.shade100,
                                  child: Icon(
                                    isSale ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isSale ? Colors.red : Colors.green,
                                  ),
                                ),
                                title: Text(
                                  '${isSale ? "مبيعات" : "مشتريات"} - فاتورة #${item['invoice_id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('الجهة: ${item['party_name'] ?? "عام"} | التاريخ: ${item['invoice_date'] ?? ""}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'الكمية: $qty',
                                      style: TextStyle(
                                        color: isSale ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('$total ل.س', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
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
