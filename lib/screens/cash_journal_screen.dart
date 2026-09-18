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
  
  String _transactionType = 'income'; // 'income' للمقبوضات، 'expense' للمدفوعات
  int? _selectedContactId;
  String _selectedContactName = 'حساب عام';
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
    final today = DateTime.now().toString().split(' ')[0];
    final transactionsData = await DatabaseHelper.instance.getDailyTransactions(today);

    setState(() {
      _contacts = contactsData.map((c) => c.toMap()).toList();
      _dailyTransactions = transactionsData;
      _isLoading = false;
    });
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.parse(_amountController.text);
    final String today = DateTime.now().toString().split(' ')[0];

    await DatabaseHelper.instance.addCashTransaction(
      contactId: _selectedContactId,
      contactName: _selectedContactName,
      type: _transactionType,
      amount: amount,
      notes: _notesController.text,
      date: today,
    );

    _amountController.clear();
    _notesController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الحركة بنجاح')),
    );

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
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
                            
                            // اختيار الحساب / العميل
                            DropdownButtonFormField<int?>(
                              value: _selectedContactId,
                              decoration: const InputDecoration(
                                labelText: 'الحساب / العميل',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('حساب عام / غير محدد'),
                                ),
                                ..._contacts.map((c) => DropdownMenuItem<int?>(
                                      value: c['id'] as int,
                                      child: Text(c['name'] ?? ''),
                                    )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedContactId = val;
                                  if (val == null) {
                                    _selectedContactName = 'حساب عام';
                                  } else {
                                    final contact = _contacts.firstWhere((c) => c['id'] == val);
                                    _selectedContactName = contact['name'] ?? 'حساب عام';
                                  }
                                });
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
                                child: const Text('حفظ الحركة', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // قائمة حركات اليوم
                  const Text(
                    'حركات اليوم',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _dailyTransactions.isEmpty
                      ? const Center(child: Text('لا توجد حركات مسجلة اليوم'))
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
                                trailing: Text(
                                  '${isIncome ? "+" : "-"}${tx['amount']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
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
