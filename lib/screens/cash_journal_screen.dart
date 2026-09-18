import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/contact_model.dart';

class CashMovementScreen extends StatefulWidget {
  const CashMovementScreen({Key? key}) : super(key: key);

  @override
  State<CashMovementScreen> createState() => _CashMovementScreenState();
}

class _CashMovementScreenState extends State<CashMovementScreen> {
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'income'; // 'income' مقبوضات, 'expense' مدفوعات
  
  ContactModel? _selectedContact;
  List<ContactModel> _contactSuggestions = [];
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  List<Map<String, dynamic>> _dailyTransactions = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _loadDailyData() async {
    final data = await DatabaseHelper.instance.getDailyTransactions(_formattedDate);
    double inc = 0.0;
    double exp = 0.0;
    for (var item in data) {
      double amt = (item['amount'] as num).toDouble();
      if (item['type'] == 'income') {
        inc += amt;
      } else {
        exp += amt;
      }
    }
    setState(() {
      _dailyTransactions = data;
      _totalIncome = inc;
      _totalExpense = exp;
    });
  }

  void _searchContacts(String query) async {
    if (query.isEmpty) {
      setState(() => _contactSuggestions = []);
      return;
    }
    final results = await DatabaseHelper.instance.searchContacts(query);
    setState(() => _contactSuggestions = results);
  }

  void _submitTransaction() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final contactName = _contactController.text.trim();

    if (amount <= 0 || contactName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال المبلغ واسم الحساب بشكل صحيح')),
      );
      return;
    }

    await DatabaseHelper.instance.addCashTransaction(
      contactId: _selectedContact?.id,
      contactName: contactName,
      type: _transactionType,
      amount: amount,
      notes: _notesController.text.trim(),
      date: _formattedDate,
    );

    _amountController.clear();
    _notesController.clear();
    _contactController.clear();
    setState(() => _selectedContact = null);
    
    _loadDailyData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الحركة بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدخال وتعديل يومية صندوق'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // شريط اختيار التاريخ
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                      onPressed: () {
                        setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                        _loadDailyData();
                      },
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(_formattedDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                      onPressed: () {
                        setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                        _loadDailyData();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // أزرار نوع الحركة (مقبوضات / مدفوعات)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _transactionType == 'income' ? Colors.green.shade50 : Colors.white,
                      side: BorderSide(color: _transactionType == 'income' ? Colors.green : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _transactionType = 'income'),
                    icon: const Icon(Icons.arrow_downward, color: Colors.green),
                    label: const Text('مقبوضات', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _transactionType == 'expense' ? Colors.red.shade50 : Colors.white,
                      side: BorderSide(color: _transactionType == 'expense' ? Colors.red : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _transactionType = 'expense'),
                    icon: const Icon(Icons.arrow_upward, color: Colors.red),
                    label: const Text('مدفوعات', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // حقل المبلغ
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.attach_money),
                hintText: 'المبلغ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            // حقل اختيار العميل / الحساب
            TextField(
              controller: _contactController,
              onChanged: _searchContacts,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                hintText: '...اسم الحساب (العميل / المورد / ا)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_contactSuggestions.isNotEmpty)
              Container(
                height: 120,
                color: Colors.white,
                child: ListView.builder(
                  itemCount: _contactSuggestions.length,
                  itemBuilder: (context, index) {
                    final c = _contactSuggestions[index];
                    return ListTile(
                      title: Text(c.name),
                      onTap: () {
                        setState(() {
                          _selectedContact = c;
                          _contactController.text = c.name;
                          _contactSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),

            // حقل البيان / ملاحظات
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.note_alt_outlined),
                hintText: 'البيان / ملاحظات',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // زر الإضافة
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submitTransaction,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text('إضافة الحركة الصندوقية', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),

            // قائمة الحركات المسجلة
            const Align(
              alignment: Alignment.centerRight,
              child: Text('حركات اليوم المسجلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dailyTransactions.length,
              itemBuilder: (context, index) {
                final item = _dailyTransactions[index];
                final isInc = item['type'] == 'income';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(item['contact_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['notes']?.isEmpty ?? true ? 'بدون بيان' : item['notes']),
                    trailing: Text(
                      '${isInc ? "" : "-"}${item['amount']} ل.س',
                      style: TextStyle(
                        color: isInc ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // كرت إجمالي حركة اليوم
            Card(
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المقبوضات:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$_totalIncome ل.س', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المدفوعات:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$_totalExpense ل.س', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي حركة اليوم:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '${_totalIncome - _totalExpense} ل.س',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (_totalIncome - _totalExpense) >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
