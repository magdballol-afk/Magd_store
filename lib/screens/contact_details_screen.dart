import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ContactDetailsScreen extends StatefulWidget {
  final int? initialContactId;

  const ContactDetailsScreen({Key? key, this.initialContactId}) : super(key: key);

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  Map<String, dynamic>? _selectedContact;

  List<Map<String, dynamic>> _combinedStatement = [];
  List<Map<String, dynamic>> _filteredStatement = [];

  bool _isLoading = true;

  // تواريخ الفلترة
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final contactsData = await DatabaseHelper.instance.getContacts();

    Map<String, dynamic>? currentContact;
    if (widget.initialContactId != null && contactsData.isNotEmpty) {
      try {
        currentContact = contactsData.firstWhere((c) => c['id'] == widget.initialContactId);
      } catch (_) {
        currentContact = contactsData.first;
      }
    } else if (contactsData.isNotEmpty) {
      currentContact = contactsData.first;
    }

    setState(() {
      _contacts = contactsData;
      _selectedContact = currentContact;
      _isLoading = false;
    });

    if (_selectedContact != null) {
      _fetchAccountStatement();
    }
  }

  // جلب كافة الفواتير وحركات الصندوق المجمعة للعميل المحدد
  Future<void> _fetchAccountStatement() async {
    if (_selectedContact == null) return;

    final contactId = _selectedContact!['id'];
    final db = await DatabaseHelper.instance.database;

    // 1. جلب الفواتير
    final invoices = await db.query(
      'invoices',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );

    // 2. جلب حركات الصندوق
    final cashTransactions = await db.query(
      'cash_transactions',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );

    List<Map<String, dynamic>> statement = [];

    // تحويل الفواتير
    for (var inv in invoices) {
      final String type = inv['type'] == 'purchase' ? 'فاتورة شراء' : 'فاتورة مبيعات';
      final double total = (inv['total_amount'] as num?)?.toDouble() ?? 0.0;
      statement.add({
        'id': inv['id'],
        'source': 'invoice',
        'title': '$type #${inv['id']}',
        'type': inv['type'],
        'amount': total,
        'date': inv['date'] ?? '',
        'raw_date': DateTime.tryParse(inv['date'].toString()) ?? DateTime.now(),
        'details': inv,
      });
    }

    // تحويل حركات الصندوق
    for (var cash in cashTransactions) {
      final String type = cash['type'] == 'expense' ? 'سند دفع / مصاريف' : 'سند قبض / إيراد';
      final double amount = (cash['amount'] as num?)?.toDouble() ?? 0.0;
      statement.add({
        'id': cash['id'],
        'source': 'cash',
        'title': '$type (صندوق)',
        'type': cash['type'],
        'amount': amount,
        'notes': cash['notes'] ?? '',
        'date': cash['date'] ?? '',
        'raw_date': DateTime.tryParse(cash['date'].toString()) ?? DateTime.now(),
        'details': cash,
      });
    }

    // ترتيب الحركات تاريخياً (الأحدث أولاً)
    statement.sort((a, b) => (b['raw_date'] as DateTime).compareTo(a['raw_date'] as DateTime));

    setState(() {
      _combinedStatement = statement;
      _applyDateFilter();
    });
  }

  // تطبيق فلترة التاريخ
  void _applyDateFilter() {
    setState(() {
      _filteredStatement = _combinedStatement.where((item) {
        final itemDate = item['raw_date'] as DateTime;
        if (_startDate != null && itemDate.isBefore(_startDate!)) return false;
        if (_endDate != null && itemDate.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
        return true;
      }).toList();
    });
  }

  // نافذة البحث المتقدم واختيار العميل
  void _showAdvancedSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = _contacts.where((c) {
              final name = (c['name'] ?? '').toString().toLowerCase();
              final phone = (c['phone'] ?? '').toString();
              return name.contains(query.toLowerCase()) || phone.contains(query);
            }).toList();

            return AlertDialog(
              title: const Text('بحث متقدم عن عميل / مورد'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'ابحث بالاسم أو رقم الهاتف...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setDialogState(() => query = val),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد نتائج مطابقة'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final contact = filtered[index];
                                final double bal = (contact['balance'] as num?)?.toDouble() ?? 0.0;
                                return ListTile(
                                  title: Text(contact['name'] ?? ''),
                                  subtitle: Text(contact['phone'] ?? 'بدون رقم'),
                                  trailing: Text(
                                    bal.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: bal >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedContact = contact;
                                    });
                                    Navigator.pop(context);
                                    _fetchAccountStatement();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // تعديل حركة صندوق
  void _editCashTransactionDialog(Map<String, dynamic> cashItem) {
    final Map<String, dynamic> cash = cashItem['details'];
    final amountController = TextEditingController(text: cash['amount'].toString());
    final notesController = TextEditingController(text: cash['notes'] ?? '');
    String type = cash['type'] ?? 'income';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تعديل حركة صندوق'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'نوع الحركة', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'income', child: Text('سند قبض (إيراد)')),
                        DropdownMenuItem(value: 'expense', child: Text('سند دفع (مصاريف)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظات / البيان', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0)),
                  onPressed: () async {
                    final double? newAmount = double.tryParse(amountController.text.trim());
                    if (newAmount == null) return;

                    await DatabaseHelper.instance.updateCashTransaction(
                      {},
                      id: cash['id'],
                      contactId: _selectedContact!['id'],
                      contactName: _selectedContact!['name'],
                      type: type,
                      amount: newAmount,
                      notes: notesController.text.trim(),
                      date: cash['date'],
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      _loadInitialData(); // تحديث الأرصدة والكشف
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تعديل حركة الصندوق بنجاح')),
                      );
                    }
                  },
                  child: const Text('حفظ التعديل', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // اختيار مدى التاريخ للفلترة
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyDateFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentBalance = (_selectedContact?['balance'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف حساب وتفاصيل العميل'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. بطاقة العميل الحالية وحقل البحث المتقدم
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedContact?['name'] ?? 'لم يتم تحديد عميل',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _selectedContact?['phone'] ?? 'بدون رقم هاتف',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAdvancedSearchDialog,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('بحث عن عميل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C6BC0),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('الرصيد الحالي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(
                              currentBalance.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: currentBalance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. زر كشف الحساب والفلترة حسب التاريخ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _fetchAccountStatement,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('كشف حساب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _startDate == null ? 'فلترة بالتاريخ' : 'تصفية الفلترة',
                        ),
                      ),
                      if (_startDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                            _applyDateFilter();
                          },
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 3. قائمة كشف الحساب والتفاصيل
                Expanded(
                  child: _filteredStatement.isEmpty
                      ? const Center(child: Text('لا توجد حركات تسوق أو صندوق لهذا العميل'))
                      : ListView.builder(
                          itemCount: _filteredStatement.length,
                          itemBuilder: (context, index) {
                            final item = _filteredStatement[index];
                            final bool isInvoice = item['source'] == 'invoice';

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isInvoice ? Colors.blue.shade100 : Colors.amber.shade100,
                                  child: Icon(
                                    isInvoice ? Icons.article : Icons.account_balance_wallet,
                                    color: isInvoice ? Colors.blue.shade900 : Colors.amber.shade900,
                                  ),
                                ),
                                title: Text(
                                  item['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'التاريخ: ${item['date']} ${item['notes'] != null && item['notes'].toString().isNotEmpty ? '\nملاحظة: ${item['notes']}' : ''}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      (item['amount'] as double).toStringAsFixed(2),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(width: 4),
                                    if (!isInvoice)
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                        onPressed: () => _editCashTransactionDialog(item),
                                      ),
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
