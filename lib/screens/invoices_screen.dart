import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'new_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  // جلب الفواتير مع اسم العميل/المورد من قاعدة البيانات
  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final rawData = await db.rawQuery('''
        SELECT 
          i.*, 
          c.name AS customer_name 
        FROM invoices i 
        LEFT JOIN contacts c ON i.party_id = c.id 
        ORDER BY i.id DESC
      ''');

      setState(() {
        _invoices = rawData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'فواتير المبيعات'),
              Tab(text: 'فواتير المشتريات'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF0277BD),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewInvoiceScreen(),
              ),
            );
            _loadInvoices();
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildInvoiceList('مبيعات'),
                  _buildInvoiceList('مشتريات'),
                ],
              ),
      ),
    );
  }

  Widget _buildInvoiceList(String type) {
    // تصفية الفواتير بحسب النوع (مبيعات أو مشتريات)
    final filteredInvoices = _invoices.where((inv) {
      final invType = inv['type'] ?? 'مبيعات';
      return invType == type;
    }).toList();

    if (filteredInvoices.isEmpty) {
      return Center(
        child: Text(
          'لا توجد فواتير $type مسجلة بعد',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredInvoices.length,
        itemBuilder: (context, index) {
          final inv = filteredInvoices[index];
          final double remaining = (inv['remaining_amount'] as num?)?.toDouble() ?? 0.0;
          final bool isPaid = remaining <= 0;
          final String status = isPaid ? 'مدفوعة' : 'آجل';
          final String customerName = inv['customer_name'] ?? 'عميل عام';
          final String currency = inv['currency'] ?? 'ليرة سورية';
          final double netTotal = (inv['net_total'] as num?)?.toDouble() ?? 0.0;
          final String formattedDate = (inv['created_at'] ?? '').toString().split('T').first;

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
                  Text('INV-${inv['id']}#', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('الجهة: $customerName'),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$netTotal $currency',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isPaid ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewInvoiceScreen(existingInvoice: inv),
                  ),
                );
                _loadInvoices();
              },
            ),
          );
        },
      ),
    );
  }
}
