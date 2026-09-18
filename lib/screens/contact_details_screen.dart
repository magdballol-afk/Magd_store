import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ContactDetailScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  Map<String, dynamic> _currentContact = {};
  List<Map<String, dynamic>> _contactInvoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentContact = widget.contact;
    _loadContactData();
  }

  // إعادة جلب بيانات العميل والفواتير من قاعدة البيانات لتحديث الرصيد
  Future<void> _loadContactData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;

    // 1. تحديث بيانات العميل لضمان قراءة أحدث رصيد
    final contactResult = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [widget.contact['id']],
    );

    if (contactResult.isNotEmpty) {
      _currentContact = contactResult.first;
    }

    // 2. جلب جميع الفواتير المسجلة للعميل
    final invoicesResult = await db.query(
      'sales_invoices',
      where: 'contact_name = ?',
      whereArgs: [_currentContact['name']],
      orderBy: 'id DESC',
    );

    setState(() {
      _contactInvoices = invoicesResult;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // قراءة الرصيد بأمان
    final double balance = ((_currentContact['balance_syr'] ?? _currentContact['balance'] ?? 0.0) as num).toDouble();

    // تحديد حالة الحساب
    String statusText = 'الحساب متزن';
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;

    if (balance > 0) {
      statusText = 'مدين (مطلوب منه)';
      statusColor = Colors.red;
      statusIcon = Icons.arrow_circle_up;
    } else if (balance < 0) {
      statusText = 'دائن (له في ذمتنا)';
      statusColor = Colors.blue;
      statusIcon = Icons.arrow_circle_down;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentContact['name'] ?? 'تفاصيل الحساب'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContactData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // كرت ملخص الحساب
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF0284C7),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                _currentContact['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text('الهاتف: ${_currentContact['phone'] ?? "غير محدد"}'),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('الرصيد الحالي:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${balance.abs().toStringAsFixed(2)} ل.س',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(statusIcon, color: statusColor, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'سجل الفواتير والعمليات:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // سجل الفواتير
                    _contactInvoices.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                'لا توجد فواتير مسجلة لهذا الحساب حتى الآن',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _contactInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = _contactInvoices[index];
                              final bool isSale = invoice['type'] == 'مبيعات';
                              final double totalAmount = ((invoice['total_amount'] ?? 0.0) as num).toDouble();
                              final double remainingAmount = ((invoice['remaining_amount'] ?? 0.0) as num).toDouble();

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSale ? Colors.green.shade100 : Colors.blue.shade100,
                                    child: Icon(
                                      isSale ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isSale ? Colors.green : Colors.blue,
                                    ),
                                  ),
                                  title: Text('${invoice['type']} - فاتورة رقم (${invoice['id']})'),
                                  subtitle: Text(
                                    'التاريخ: ${invoice['date'] != null ? invoice['date'].toString().split('T')[0] : ""}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${totalAmount.toStringAsFixed(2)} ل.س',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (remainingAmount > 0)
                                        Text(
                                          'متبقي: ${remainingAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, color: Colors.red),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
