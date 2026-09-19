import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CashJournalScreen extends StatefulWidget {
  const CashJournalScreen({Key? key}) : super(key: key);

  @override
  State<CashJournalScreen> createState() => _CashJournalScreenState();
}

class _CashJournalScreenState extends State<CashJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _contactSearchController = TextEditingController();

  String _transactionType = 'income'; // 'income' للمقبوضات، 'expense' للمدفوعات
  int? _selectedContactId;
  String _selectedContactName = 'حساب عام';
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _dailyTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final contactsData = await DatabaseHelper.instance.getContacts();
    final formattedDate = _selectedDate.toString().split(' ')[0];
    final transactionsData = await DatabaseHelper.instance.getDailyTransactions(formattedDate);

    setState(() {
      _contacts = contactsData.map((c) => c.toMap()).toList();
      _dailyTransactions = transactionsData;
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.parse(_amountController.text);
    final String formattedDate = _selectedDate.toString().split(' ')[0];

    await DatabaseHelper.instance.addCashTransaction(
      contactId: _selectedContactId,
      contactName: _selectedContactName,
      type: _transactionType,
      amount: amount,
      notes: _notesController.text,
      date: formattedDate,
    );

    _amountController.clear();
    _notesController.clear();
    _contactSearchController.clear();
    setState(() {
      _selectedContactId = null;
      _selectedContactName = 'حساب عام';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الحركة بنجاح')),
      );
    }

    _loadData();
  }

  void _showEditDialog(Map<String, dynamic> tx) {
    final editAmountController = TextEditingController(text: tx['amount'].toString());
    final editNotesController = TextEditingController(text: tx['notes'] ?? '');
    String editType = tx['type'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('تعديل الحركة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('مقبوضات'),
                        value: 'income',
                        groupValue: editType,
                        onChanged: (val) => setDialogState(() => editType = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('مدفوعات'),
                        value: 'expense',
                        groupValue: editType,
                        onChanged: (val) => setDialogState(() => editType = val!),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: editAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: editNotesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات / البيان', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final db = await DatabaseHelper.instance.database;
                  final double oldAmount = ((tx['amount'] ?? 0) as num).toDouble();
                  final double newAmount = double.tryParse(editAmountController.text) ?? oldAmount;
                  final String oldType = tx['type'];
                  final int? contactId = tx['contact_id'];

                  // 1. تحديث جدول الحركات
                  await db.update(
                    'cash_transactions',
                    {
                      'type': editType,
                      'amount': newAmount,
                      'notes': editNotesController.text,
                    },
                    where: 'id = ?',
                    whereArgs: [tx['id']],
                  );

                  // 2. تحديث رصيد العميل في جدول contacts
                  if (contactId != null) {
                    final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [contactId]);
                    if (contactResult.isNotEmpty) {
                      double currentBalance = ((contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0) as num).toDouble();

                      // إلغاء تأثير الحركة القديمة
                      if (oldType == 'income') {
                        currentBalance += oldAmount; // القبض السابق كان ينقص الدين
                      } else {
                        currentBalance -= oldAmount; // الدفع السابق كان يزيد الدين
                      }

                      // تطبيق تأثير الحركة الجديدة
                      if (editType == 'income') {
                        currentBalance -= newAmount;
                      } else {
                        currentBalance += newAmount;
                      }

                      await db.update(
                        'contacts',
                        {
                          'balance_syr': currentBalance,
                          'balance': currentBalance,
                        },
                        where: 'id = ?',
                        whereArgs: [contactId],
                      );
                    }
                  }

                  if (mounted) Navigator.pop(context);
                  _loadData();
                },
                child: const Text('حفظ التعديل'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteTransaction(Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت تأكد من رغبتك في حذف هذه الحركة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              final int id = tx['id'];
              final double amount = ((tx['amount'] ?? 0) as num).toDouble();
              final String type = tx['type'];
              final int? contactId = tx['contact_id'];

              // 1. حذف الحركة من الجدول
              await db.delete(
                'cash_transactions',
                where: 'id = ?',
                whereArgs: [id],
              );

              // 2. عكس التأثير على رصيد العميل
              if (contactId != null) {
                final contactResult = await db.query('contacts', where: 'id = ?', whereArgs: [contactId]);
                if (contactResult.isNotEmpty) {
                  double currentBalance = ((contactResult.first['balance_syr'] ?? contactResult.first['balance'] ?? 0.0) as num).toDouble();

                  if (type == 'income') {
                    currentBalance += amount;
                  } else {
                    currentBalance -= amount;
                  }

                  await db.update(
                    'contacts',
                    {
                      'balance_syr': currentBalance,
                      'balance': currentBalance,
                    },
                    where: 'id = ?',
                    whereArgs: [contactId],
                  );
                }
              }

              if (mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _contactSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدخال وتعديل يومية صندوق'),
        backgroundColor: const Color(0xFF0277BD),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // نموذج إضافة حركة جديدة
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تسجيل حركة صندوق جديدة',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            
                            // تحديد نوع الحركة (مقبوضات / مدفوعات)
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('مقبوضات (+)'),
                                    value: 'income',
                                    groupValue: _transactionType,
                                    onChanged: (val) => setState(() => _transactionType = val!),
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('مدفوعات (-)'),
                                    value: 'expense',
                                    groupValue: _transactionType,
                                    onChanged: (val) => setState(() => _transactionType = val!),
                                  ),
                                ),
                              ],
                            ),
                            
                            // اختيار الحساب / العميل - بحث متقدم
                            RawAutocomplete<Map<String, dynamic>>(
                              textEditingController: _contactSearchController,
                              focusNode: FocusNode(),
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                final List<Map<String, dynamic>> allOptions = [
                                  {'id': null, 'name': 'حساب عام / غير محدد'},
                                  ..._contacts,
                                ];
                                if (textEditingValue.text.isEmpty) return allOptions;
                                return allOptions.where((option) {
                                  final name = option['name'].toString().toLowerCase();
                                  final input = textEditingValue.text.toLowerCase();
                                  return name.contains(input);
                                });
                              },
                              displayStringForOption: (option) => option['name'] ?? '',
                              onSelected: (selection) {
                                setState(() {
                                  _selectedContactId = selection['id'];
                                  _selectedContactName = selection['name'] ?? 'حساب عام';
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'الحساب / العميل (ابحث هنا)',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: controller.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              controller.clear();
                                              setState(() {
                                                _selectedContactId = null;
                                                _selectedContactName = 'حساب عام';
                                              });
                                            },
                                          )
                                        : null,
                                    border: const OutlineInputBorder(),
                                  ),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      width: MediaQuery.of(context).size.width - 64,
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder: (context, index) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);
                                          return ListTile(
                                            title: Text(option['name'] ?? ''),
                                            onTap: () => onSelected(option),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // المبلغ
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'المبلغ',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'يرجى إدخال المبلغ';
                                if (double.tryParse(val) == null) return 'أدخل رقم صحيح';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // ملاحظات
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'ملاحظات / البيان',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // زر الحفظ
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0277BD),
                                ),
                                onPressed: _submitTransaction,
                                child: const Text('حفظ الحركة', style: TextStyle(fontSize: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // منقي اختيار التاريخ وقائمة الحركة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'حركات يوم: $formattedDateStr',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('تغيير التاريخ'),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _dailyTransactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('لا توجد حركات مسجلة لهذا اليوم'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dailyTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = _dailyTransactions[index];
                            final isIncome = tx['type'] == 'income';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(tx['contact_name'] ?? 'حساب عام'),
                                subtitle: Text(tx['notes'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isIncome ? "+" : "-"}${tx['amount']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isIncome ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showEditDialog(tx),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteTransaction(tx),
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
    );
  }
}
