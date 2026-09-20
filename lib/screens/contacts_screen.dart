import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // إعادة تحميل قائمة العملاء من قاعدة البيانات
  Future<void> _refreshContacts() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getContacts();
    setState(() {
      _allContacts = data;
      _applySearch(_searchController.text);
      _isLoading = false;
    });
  }

  // فلترة الحسابات حسب اسم العميل أو الهاتف
  void _applySearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredContacts = List.from(_allContacts);
      } else {
        _filteredContacts = _allContacts.where((contact) {
          final name = (contact['name'] ?? '').toString().toLowerCase();
          final phone = (contact['phone'] ?? '').toString().toLowerCase();
          return name.contains(q) || phone.contains(q);
        }).toList();
      }
    });
  }

  // نافذة إضافة عميل جديد
  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final balanceController = TextEditingController(text: '0.0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة حساب / عميل جديد'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: minContentSize,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم العميل / الحساب',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الاسم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'الرصيد الأولي',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty && double.tryParse(value.trim()) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6BC0),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final String name = nameController.text.trim();
                final String phone = phoneController.text.trim();
                final double balance = double.tryParse(balanceController.text.trim()) ?? 0.0;

                await DatabaseHelper.instance.insertContact({
                  'name': name,
                  'phone': phone,
                  'balance': balance,
                });

                if (mounted) {
                  Navigator.pop(context);
                  _refreshContacts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة العميل بنجاح')),
                  );
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // عرض نافذة كشف الحساب والفلترة حسب التاريخ
  void _showAccountStatement(Map<String, dynamic> contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AccountStatementSheet(contact: contact),
    ).then((_) => _refreshContacts());
  }

  static const MainAxisSize minContentSize = MainAxisSize.min;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحسابات والعملاء'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: Column(
        children: [
          // 1. حقل البحث المتقدم
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _applySearch,
              decoration: InputDecoration(
                hintText: 'بحث باسم العميل أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? const Center(child: Text('لا يوجد نتائج متطابقة'))
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final double balance = (contact['balance'] as num?)?.toDouble() ?? 0.0;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              onTap: () => _showAccountStatement(contact),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF5C6BC0),
                                child: Text(
                                  (contact['name'] as String?)?.isNotEmpty == true
                                      ? contact['name'][0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(contact['name'] ?? ''),
                              subtitle: Text(contact['phone'] ?? 'بدون رقم هاتف'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    balance.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: balance >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'عرض كشف الحساب >',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContactDialog,
        backgroundColor: const Color(0xFF5C6BC0),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('إضافة عميل', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// كشف حساب عميل مفصل مع إمكانية الفلترة والتنقل للحركات
class _AccountStatementSheet extends StatefulWidget {
  final Map<String, dynamic> contact;
  const _AccountStatementSheet({Key? key, required this.contact}) : super(key: key);

  @override
  State<_AccountStatementSheet> createState() => _AccountStatementSheetState();
}

class _AccountStatementSheetState extends State<_AccountStatementSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = true;
  List<Map<String, dynamic>> _movements = [];

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() => _loading = true);
    final db = await DatabaseHelper.instance.database;
    final int contactId = widget.contact['id'];

    // جلب الفواتير المرتطبة بالعميل
    final invoices = await db.query(
      'invoices',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );

    // جلب حركات الصندوق المرتبطة بالعميل
    final cashTx = await db.query(
      'cash_transactions',
      where: 'contact_id = ?',
      whereArgs: [contactId],
    );

    List<Map<String, dynamic>> list = [];

    for (var inv in invoices) {
      list.add({
        'id': inv['id'],
        'source': 'invoice',
        'title': inv['type'] == 'sale' ? 'فاتورة مبيعات #${inv['id']}' : 'فاتورة مشتريات #${inv['id']}',
        'amount': inv['total_amount'],
        'date': inv['date'],
        'details': inv,
      });
    }

    for (var ctx in cashTx) {
      list.add({
        'id': ctx['id'],
        'source': 'cash',
        'title': ctx['type'] == 'income' ? 'قبض صندوق #${ctx['id']}' : 'صرف صندوق #${ctx['id']}',
        'amount': ctx['amount'],
        'date': ctx['date'],
        'details': ctx,
      });
    }

    // الفلترة بالتاريخ إن وجد
    if (_startDate != null) {
      list = list.where((item) {
        final d = DateTime.tryParse(item['date'].toString());
        if (d == null) return true;
        return d.isAfter(_startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (_endDate != null) {
      list = list.where((item) {
        final d = DateTime.tryParse(item['date'].toString());
        if (d == null) return true;
        return d.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // ترتيب الحركات حسب التاريخ
    list.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    setState(() {
      _movements = list;
      _loading = false;
    });
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
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
      _loadMovements();
    }
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    final isInvoice = item['source'] == 'invoice';
    final details = item['details'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التاريخ: ${item['date']}'),
            const SizedBox(height: 8),
            Text('المبلغ: ${item['amount']}'),
            const SizedBox(height: 8),
            if (isInvoice) ...[
              Text('المدفوع: ${details['paid_amount']}'),
              Text('نوع الفاتورة: ${details['type']}'),
            ] else ...[
              Text('البيان/الملاحظات: ${details['notes'] ?? 'بدون'}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = (widget.contact['balance'] as num?)?.toDouble() ?? 0.0;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF5C6BC0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كشف حساب: ${widget.contact['name']}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الرصيد الحالي: ${balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.date_range, color: Colors.white),
                  onPressed: _pickDateRange,
                ),
              ],
            ),
          ),

          if (_startDate != null || _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'من: ${_startDate != null ? dateFormat.format(_startDate!) : 'الكل'}  |  إلى: ${_endDate != null ? dateFormat.format(_endDate!) : 'الكل'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadMovements();
                    },
                    child: const Text('إلغاء الفلترة'),
                  )
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _movements.isEmpty
                    ? const Center(child: Text('لا يوجد حركات مسجلة ضمن هذه الفترة'))
                    : ListView.builder(
                        controller: controller,
                        itemCount: _movements.length,
                        itemBuilder: (context, index) {
                          final item = _movements[index];
                          final isInvoice = item['source'] == 'invoice';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              onTap: () => _showDetailsDialog(item),
                              leading: Icon(
                                isInvoice ? Icons.receipt_long : Icons.account_balance_wallet,
                                color: isInvoice ? Colors.indigo : Colors.orange,
                              ),
                              title: Text(item['title']),
                              subtitle: Text(item['date'] ?? ''),
                              trailing: Text(
                                (item['amount'] as num).toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
