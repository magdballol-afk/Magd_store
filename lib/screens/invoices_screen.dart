import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'new_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

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

  // جلب الفواتير المحفوظة من جدول sales_invoices
  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      // ترتيب الفواتير بحيث تظهر الأحدث في الأعلى
      final data = await db.query('sales_invoices', orderBy: 'id DESC');
      setState(() {
        _invoices = data;
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
        title: const Text('قائمة الفواتير'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0284C7),
        onPressed: () async {
          // التوجيه لشاشة إضافة فاتورة جديدة وانتظار النتيجة
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewInvoiceScreen(),
            ),
          );
          // في حال تم حفظ الفاتورة بنجاح نقوم بإعادة تحميل القائمة
          if (result == true) {
            _loadInvoices();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد فواتير محفوظة حالياً',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _invoices[index];
                    final isSale = invoice['type'] == 'مبيعات';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSale ? Colors.green.shade100 : Colors.blue.shade100,
                          child: Icon(
                            isSale ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isSale ? Colors.green : Colors.blue,
                          ),
                        ),
                        title: Text(
                          '${invoice['type']} - ${invoice['contact_name'] ?? "عميل نقدي"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'التاريخ: ${invoice['date'] != null ? invoice['date'].toString().split('T')[0] : ""}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${invoice['total_amount']} ل.س',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            if ((invoice['remaining_amount'] ?? 0.0) > 0)
                              Text(
                                'متبقي: ${invoice['remaining_amount']} ل.س',
                                style: const TextStyle(fontSize: 11, color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
