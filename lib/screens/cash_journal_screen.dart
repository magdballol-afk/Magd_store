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

  double _totalIn = 0.0;
  double _totalOut = 0.0;

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  Future<void> _loadJournal() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      final results = await db.query('journal_entries', orderBy: 'date DESC');

      double inSum = 0.0;
      double outSum = 0.0;

      for (var item in results) {
        // تحويل آمن لتجنب خطأ toDouble على Object
        double amt = (item['amount'] as num?)?.toDouble() ?? 0.0;
                     
        String type = (item['type'] ?? '').toString();

        if (type == 'in' || type == 'قبض' || type == 'مقبوضات') {
          inSum += amt;
        } else {
          outSum += amt;
        }
      }

      setState(() {
        _entries = results;
        _totalIn = inSum;
        _totalOut = outSum;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double netBalance = _totalIn - _totalOut;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الصندوق'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('المقبوضات', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$_totalIn', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 30, width: 1, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text('المدفوعات', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$_totalOut', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 30, width: 1, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text('الرصيد الصافي', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$netBalance', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('لا توجد قيود مسجلة في الصندوق'))
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final item = _entries[index];
                            final String type = (item['type'] ?? '').toString();
                            final bool isIn = type == 'in' || type == 'قبض' || type == 'مقبوضات';
                            
                            double amt = (item['amount'] as num?)?.toDouble() ?? 0.0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isIn ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(
                                    isIn ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isIn ? Colors.green : Colors.red,
                                  ),
                                ),
                                title: Text(item['description'] ?? 'قيد صندوق'),
                                subtitle: Text('التاريخ: ${item['date'] ?? ''}'),
                                trailing: Text(
                                  '$amt',
                                  style: TextStyle(
                                    color: isIn ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
