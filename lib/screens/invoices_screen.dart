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

    // تنسيق التاريخ للبحث في قاعدة البيانات (YYYY-MM-DD)
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // استعلام الفواتير مع اسم العميل
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0288D1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadInvoices();
    }
  }

  void _openInvoiceDetails(int invoiceId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewInvoiceScreen(invoiceId: invoiceId),
      ),
    );

    // إعادة تحميل البيانات بعد تعديل الفاتورة لتعديل الأرصدة والقائمة
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
          // قسم الفلترة حسب التاريخ والنوع
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Column(
              children: [
                // اختيار التاريخ
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0288D1),
                        side: const BorderSide(color: Color(0xFF0288D1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // فلترة نوع الفاتورة
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

          // قائمة الفواتير
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isSale
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                                child: Icon(
                                  isSale
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isSale ? Colors.green : Colors.orange[800],
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'فاتورة #${inv['id']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSale
                                          ? Colors.green[50]
                                          : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSale
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                    child: Text(
                                      isSale ? 'مبيعات' : 'مشتريات',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSale
                                            ? Colors.green[800]
                                            : Colors.orange[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAlignment.start,
                                  children: [
                                    Text(
                                      'الحساب: ${inv['contact_name'] ?? 'بدون حساب'}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الإجمالي: $total',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isSale
                                            ? Colors.green[800]
                                            : Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () => _openInvoiceDetails(inv['id']),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewInvoiceScreen(),
            ),
          );
          if (result == true) {
            _loadInvoices();
          }
        },
        backgroundColor: const Color(0xFF0288D1),
        child: const Icon(Icons.add),
      ),
    );
  }
}
