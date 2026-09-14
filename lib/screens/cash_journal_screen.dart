import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CashJournalScreen extends StatefulWidget {
  const CashJournalScreen({super.key});

  @override
  State<CashJournalScreen> createState() => _CashJournalScreenState();
}

class _CashJournalScreenState extends State<CashJournalScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query('cash_journal', orderBy: 'date DESC');
      
      double income = 0.0;
      double expense = 0.0;

      for (var item in data) {
        double amt = (item['amount'] ?? 0.0).toDouble();
        if (amt >= 0) {
          income += amt;
        } else {
          expense += amt.abs();
        }
      }

      setState(() {
        _entries = data;
        _totalIncome = income;
        _totalExpense = expense;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEntryDialog(bool isIncome) {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isIncome ? 'إضافة سند قبض (+)' : 'إضافة سند صرف (-)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'البيان / الوصف',
                    border: OutlineInputBorder(),
                  ),
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
              onPressed: () async {
                double? val = double.tryParse(amountController.text.trim());
                if (val == null || val <= 0) return;

                double finalAmount = isIncome ? val : -val;
                final db = await DatabaseHelper.instance.database;
                await db.insert('cash_journal', {
                  'description': descController.text.trim().isEmpty 
                      ? (isIncome ? 'سند قبض' : 'سند صرف')
                      : descController.text.trim(),
                  'amount': finalAmount,
                  'date': DateTime.now().toString().split('.')[0],
                });

                if (mounted) Navigator.pop(context);
                _loadEntries();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    double balance = _totalIncome - _totalExpense;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي المقبوضات:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('+$_totalIncome ل.س', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي المدفوعات:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                Text('-$_totalExpense ل.س', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('رصيد الصندوق الحالي:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '$balance ل.س',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.blue.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الصندوق والتدفقات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: () => _showAddEntryDialog(true),
                          icon: const Icon(Icons.add),
                          label: const Text('قبض'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () => _showAddEntryDialog(false),
                          icon: const Icon(Icons.remove),
                          label: const Text('دفع'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('لا توجد حركة في الصندوق حالياً'))
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final double amount = (entry['amount'] ?? 0.0).toDouble();
                            final isIncome = amount >= 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(entry['description'] ?? 'قيد صندوق'),
                                subtitle: Text(entry['date'] ?? ''),
                                trailing: Text(
                                  '$amount ل.س',
                                  style: TextStyle(
                                    color: isIncome ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
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
