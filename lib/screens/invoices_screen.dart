import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'new_invoice_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _typeFilter = 'all'; // 'all', 'sale', 'purchase'
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    String query = '''
      SELECT i.*, c.name AS contact_name 
      FROM invoices i
      LEFT JOIN contacts c ON i.contact_id = c.id
      WHERE strftime('%Y-%m-%d', i.date) = ?
    ''';

    List<dynamic> whereArgs = [formattedDate];

    if (_typeFilter != 'all') {
      query += ' AND i.type = ?';
      whereArgs.add(_typeFilter);
    }

    query += ' ORDER BY i.id DESC';

    final result = await db.rawQuery(query, whereArgs);

    setState(() {
      _invoices = result;
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadInvoices();
    }
  }

  void _openInvoice({int? invoiceId, String? type}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewInvoiceScreen(
          invoiceId: invoiceId,
          type: type,
        ),
      ),
    );

    if (result == true || result == null) {
      _loadInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateDisplay = DateFormat('yyyy/MM/dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الفواتير'),
        backgroundColor: const Color(0xFF0288D1),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF0288D1), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'تاريخ الفواتير: $dateDisplay',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: const Text('تغيير'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('الكل'),
                      selected: _typeFilter == 'all',
                      selectedColor: const Color(0xFF0288D1),
                      labelStyle: TextStyle(
                        color: _typeFilter == 'all' ? Colors.white : Colors.black87,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _typeFilter = 'all');
                          _loadInvoices();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('مبيعات'),
                      selected: _typeFilter == 'sale',
                      selectedColor: Colors.green[700],
                      labelStyle: TextStyle(
                        color: _typeFilter == 'sale' ? Colors.white : Colors.black87,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _typeFilter = 'sale');
                          _loadInvoices();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('مشتريات'),
                      selected: _typeFilter == 'purchase',
                      selectedColor: Colors.orange[800],
                      labelStyle: TextStyle(
                        color: _typeFilter == 'purchase' ? Colors.white : Colors.black87,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _typeFilter = 'purchase');
                          _loadInvoices();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد فواتير محفوظة لهذا التاريخ',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final inv = _invoices[index];
                          final bool isSale = inv['type'] == 'sale';
                          final double total = (inv['total_amount'] ?? 0.0).toDouble();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSale
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                                child: Icon(
                                  isSale ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isSale ? Colors.green : Colors.orange[800],
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'فاتورة #${inv['id']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    isSale ? 'مبيعات' : 'مشتريات',
                                    style: TextStyle(
                                      color: isSale ? Colors.green[800] : Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الحساب: ${inv['contact_name'] ?? 'بدون حساب'}'),
                                  Text(
                                    'الإجمالي: $total',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              onTap: () => _openInvoice(
                                invoiceId: inv['id'] as int?,
                                type: inv['type'] as String?,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openInvoice(),
        backgroundColor: const Color(0xFF0288D1),
        child: const Icon(Icons.add),
      ),
    );
  }
}
