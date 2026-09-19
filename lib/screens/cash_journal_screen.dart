import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CashJournalScreen extends StatefulWidget {
  const CashJournalScreen({Key? key}) : super(key: key);

  @override
  State<CashJournalScreen> createState() => _CashJournalScreenState();
}

class _CashJournalScreenState extends State<CashJournalScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _dailyTransactions = [];

  bool _isLoading = true;
  String _transactionType = 'income'; // 'income' (قبض) أو 'expense' (دفع)
  int? _selectedContactId;
  String _selectedContactName = 'عام / غير محدد';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _contactSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // جلب البيانات
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final contactsData = await DatabaseHelper.instance.getContacts();
    final formattedDate = _selectedDate.toString().split(' ')[0];
    final transactionsData = await DatabaseHelper.instance.getDailyTransactions(formattedDate);

    setState(() {
      _contacts = List<Map<String, dynamic>>.from(contactsData);
      _dailyTransactions = List<Map<String, dynamic>>.from(transactionsData);
      _isLoading = false;
    });
  }

  // إضافة حركة جديدة وتحديث رصيد العميل
  Future<void> _submitTransaction() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
      );
      return;
    }

    final String formattedDate = _selectedDate.toString().split(' ')[0];

    // إعداد الخريطة لضمان توافقها المباشر مع DatabaseHelper
    final Map<String, dynamic> row = {
      'contact_id': _selectedContactId,
      'contact_name': _selectedContactName,
      'type': _transactionType,
      'amount': amount,
      'notes': _notesController.text,
      'date': formattedDate,
    };

    await DatabaseHelper.instance.addCashTransaction(row);

    // تحديث رصيد العميل مباشرة
    if (_selectedContactId != null) {
      double adjustment = (_transactionType == 'income') ? -amount : amount;
      await DatabaseHelper.instance.updateContactBalance(_selectedContactId, adjustment);
    }

    _amountController.clear();
    _notesController.clear();
    _contactSearchController.clear();
    setState(() {
      _selectedContactId = null;
      _selectedContactName = 'عام / غير محدد';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الحركة وتحديث رصيد العميل بنجاح')),
      );
      _loadData();
    }
  }

  // حذف حركة صندوق وتعديل رصيد العميل
  Future<void> _deleteTransaction(Map<String, dynamic> item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت أحدث برغبتك في حذف هذه الحركة؟ سيتم تعديل رصيد العميل تلقائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final int transactionId = item['id'];
      final int? contactId = item['contact_id'];
      final double amount = ((item['amount'] ?? 0.0) as num).toDouble();
      final String type = item['type'] ?? 'income';

      // 1. عكس التأثير المالي على رصيد العميل
      if (contactId != null) {
        double adjustment = (type == 'income') ? amount : -amount;
        await DatabaseHelper.instance.updateContactBalance(contactId, adjustment);
      }

      // 2. حذف الحركة من جدول الحركات
      await DatabaseHelper.instance.deleteCashTransaction(transactionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحركة وتحديث رصيد العميل')),
        );
        _loadData();
      }
    }
  }

  // تعديل حركة صندوق وتعديل رصيد العميل
  Future<void> _editTransaction(Map<String, dynamic> item) async {
    final TextEditingController editAmountController = TextEditingController(text: item['amount'].toString());
    final TextEditingController editNotesController = TextEditingController(text: item['notes'] ?? '');
    String editType = item['type'] ?? 'income';
    int? editContactId = item['contact_id'];
    String editContactName = item['contact_name'] ?? 'عام / غير محدد';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تعديل حركة الصندوق'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('قبض'),
                            value: 'income',
                            groupValue: editType,
                            onChanged: (val) => setDialogState(() => editType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('دفع'),
                            value: 'expense',
                            groupValue: editType,
                            onChanged: (val) => setDialogState(() => editType = val!),
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<int?>(
                      value: editContactId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('عام / غير محدد'),
                        ),
                        ..._contacts.map((c) => DropdownMenuItem<int?>(
                              value: c['id'],
                              child: Text(c['name'] ?? ''),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          editContactId = val;
                          if (val == null) {
                            editContactName = 'عام / غير محدد';
                          } else {
                            final c = _contacts.firstWhere((element) => element['id'] == val);
                            editContactName = c['name'] ?? 'عام / غير محدد';
                          }
                        });
                      },
                      decoration: const InputDecoration(labelText: 'الجهة / اسم العميل'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: editAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'المبلغ'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: editNotesController,
                      decoration: const InputDecoration(labelText: 'البيان / ملاحظات'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0)),
                  onPressed: () async {
                    final double? newAmount = double.tryParse(editAmountController.text);
                    if (newAmount == null || newAmount <= 0) return;

                    final double oldAmount = ((item['amount'] ?? 0.0) as num).toDouble();
                    final String oldType = item['type'] ?? 'income';
                    final int? oldContactId = item['contact_id'];

                    // 1. إعادة تسوية رصيد العميل القديم
                    if (oldContactId != null) {
                      double reverseOld = (oldType == 'income') ? oldAmount : -oldAmount;
                      await DatabaseHelper.instance.updateContactBalance(oldContactId, reverseOld);
                    }

                    // 2. تطبيق تأثير الحركة الجديدة على رصيد العميل الجديد
                    if (editContactId != null) {
                      double applyNew = (editType == 'income') ? -newAmount : newAmount;
                      await DatabaseHelper.instance.updateContactBalance(editContactId, applyNew);
                    }

                    // 3. تحديث الحركة في قاعدة البيانات باختيار الخريطة
                    final Map<String, dynamic> row = {
                      'id': item['id'],
                      'contact_id': editContactId,
                      'contact_name': editContactName,
                      'type': editType,
                      'amount': newAmount,
                      'notes': editNotesController.text,
                      'date': item['date'] ?? _selectedDate.toString().split(' ')[0],
                    };

                    await DatabaseHelper.instance.updateCashTransaction(row);

                    if (mounted) {
                      Navigator.of(ctx).pop();
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تعديل الحركة وتحديث الرصيد بنجاح')),
                      );
                    }
                  },
                  child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double get _totalIncome {
    return _dailyTransactions
        .where((t) => t['type'] == 'income')
        .fold(0.0, (sum, item) => sum + ((item['amount'] ?? 0.0) as num).toDouble());
  }

  double get _totalExpense {
    return _dailyTransactions
        .where((t) => t['type'] == 'expense')
        .fold(0.0, (sum, item) => sum + ((item['amount'] ?? 0.0) as num).toDouble());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة الصندوق اليومية'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اختيار التاريخ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التاريخ: ${_selectedDate.toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('تغيير التاريخ'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadData();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // كروت الإحصائيات (مقبوضات ومصروفات)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المقبوضات', style: TextStyle(color: Colors.green, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                _totalIncome.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المدفوعات', style: TextStyle(color: Colors.red, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                _totalExpense.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // نموذج تسجيل حركة صندوق جديدة
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('تسجيل حركة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('قبض'),
                                  value: 'income',
                                  groupValue: _transactionType,
                                  onChanged: (val) => setState(() => _transactionType = val!),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('دفع'),
                                  value: 'expense',
                                  groupValue: _transactionType,
                                  onChanged: (val) => setState(() => _transactionType = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // البحث عن العميل / الجهة
                          RawAutocomplete<Map<String, dynamic>>(
                            textEditingController: _contactSearchController,
                            focusNode: FocusNode(),
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              final List<Map<String, dynamic>> allOptions = [
                                {'id': null, 'name': 'عام / غير محدد'},
                                ..._contacts,
                              ];
                              if (textEditingValue.text.isEmpty) return allOptions;
                              return allOptions.where((option) {
                                final name = option['name'].toString().toLowerCase();
                                return name.contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            displayStringForOption: (option) => option['name'] ?? '',
                            onSelected: (selection) {
                              setState(() {
                                _selectedContactId = selection['id'];
                                _selectedContactName = selection['name'] ?? 'عام / غير محدد';
                              });
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'الجهة / اسم العميل',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  child: Container(
                                    constraints: const BoxConstraints(maxHeight: 180),
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

                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'المبلغ',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات / البيان',
                              prefixIcon: Icon(Icons.notes),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C6BC0),
                              ),
                              onPressed: _submitTransaction,
                              child: const Text('حفظ الحركة', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // سجل الحركات اليومية
                  const Text('حركات اليوم:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  _dailyTransactions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text('لا توجد حركات صندوق مسجلة لهذا اليوم')),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dailyTransactions.length,
                          itemBuilder: (context, index) {
                            final item = _dailyTransactions[index];
                            final bool isIncome = item['type'] == 'income';
                            final double amount = ((item['amount'] ?? 0.0) as num).toDouble();

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
                                title: Text(item['contact_name'] ?? 'عام'),
                                subtitle: Text(item['notes'] != null && item['notes'].toString().isNotEmpty
                                    ? item['notes']
                                    : (isIncome ? 'دفعة مقبوضة' : 'دفعة مدفوعة')),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      amount.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isIncome ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _editTransaction(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _deleteTransaction(item),
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
