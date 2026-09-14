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
      setState(() {
        _entries = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الصندوق والتدفّقات المالية'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('لا توجد قيود في الصندوق حالياً'))
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
    );
  }
}
