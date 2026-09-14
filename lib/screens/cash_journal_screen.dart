import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../database/database_helper.dart';

class CashJournalScreen extends StatefulWidget {
  const CashJournalScreen({super.key});

  @override
  State<CashJournalScreen> createState() => _CashJournalScreenState();
}

class _CashJournalScreenState extends State<CashJournalScreen> {
  double _totalCashSYP = 0.0;
  double _totalCashUSD = 0.0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _journalEntries = [];
  List<ContactModel> _contactsList = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadCashBalances(),
      _loadJournalEntries(),
      _loadContacts(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadCashBalances() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rawEntries = await db.query('cash_journal');

      double syp = 0.0;
      double usd = 0.0;

      for (var entry in rawEntries) {
        final double amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
        final String type = entry['type']?.toString() ?? 'إيداع';
        final String currency = entry['currency']?.toString() ?? 'ليرة سورية';

        bool isInflow = (type == 'إيداع' || type == 'سند قبض');

        if (currency == 'ليرة سورية') {
          syp += isInflow ? amount : -amount;
        } else {
          usd += isInflow ? amount : -amount;
        }
      }

      _totalCashSYP = syp;
      _totalCashUSD = usd;
    } catch (e) {
      debugPrint('خطأ في تحميل رصيد الصندوق: $e');
    }
  }

  Future<void> _loadJournalEntries() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rawData = await db.query('cash_journal', orderBy: 'id DESC');
      _journalEntries = rawData;
    } catch (e) {
      debugPrint('خطأ في تحميل حركات الصندوق: $e');
    }
  }

  Future<void> _loadContacts() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rawData = await db.query('parties');

      _contactsList = rawData.map((map) {
        return ContactModel.fromMap(map);
      }).toList();
    } catch (e) {
      debugPrint('خطأ في تحميل الجهات: $e');
    }
  }

  void _showAddTransactionDialog() {
    String entryType = 'سند قبض';
    String currency = 'ليرة سورية';
    ContactModel? selectedContact;
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulWidget(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة حركة صندوق جديدة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: entryType,
                      decoration: const InputDecoration(labelText: 'نوع الحركة', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'سند قبض', child: Text('سند قبض (قبض من عميل/مصدر)')),
                        DropdownMenuItem(value: 'سند صرف', child: Text('سند صرف (دفعة لمورد/مصروف)')),
                      ],
                      onChanged: (val) => setDialogState(() => entryType = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ContactModel>(
                      value: selectedContact,
                      decoration: const InputDecoration(
                        labelText: 'مرتبط بـ (عميل/مورد) - اختياري',
                        border: OutlineInputBorder(),
                      ),
                      items: _contactsList.map((contact) {
                        return DropdownMenuItem(
                          value: contact,
                          child: Text(contact.name),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedContact = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: currency,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'ليرة سورية', child: Text('ل.س')),
                              DropdownMenuItem(value: 'دولار (\$)', child: Text('\$')),
                            ],
                            onChanged: (val) => setDialogState(() => currency = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'البيان / ملاحظات', border: OutlineInputBorder()),
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
                    final double amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount <= 0) return;

                    final db = await DatabaseHelper.instance.database;

                    await db.insert('cash_journal', {
                      'party_id': selectedContact?.id,
                      'type': entryType,
                      'amount': amount,
                      'currency': currency,
                      'notes': notesController.text.trim(),
                      'date': DateTime.now().toIso8601String().split('T').first,
                    });

                    final String? contactIdStr = selectedContact?.id;
                    if (selectedContact != null && contactIdStr != null && contactIdStr.isNotEmpty) {
                      final int contactId = int.tryParse(contactIdStr) ?? 0;
                      if (contactId > 0) {
                        double impact = (entryType == 'سند قبض') ? -amount : amount;

                        if (currency == 'ليرة سورية') {
                          await db.rawUpdate(
                            'UPDATE parties SET balance_syp = COALESCE(balance_syp, 0) + ? WHERE id = ?',
                            [impact, contactId],
                          );
                        } else {
                          await db.rawUpdate(
                            'UPDATE parties SET balance_usd = COALESCE(balance_usd, 0) + ? WHERE id = ?',
                            [impact, contactId],
                          );
                        }
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      _refreshData();
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الصندوق (الخزينة)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        icon: const Icon(Icons.add_card),
        label: const Text('حركة جديدة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'إجمالي رصيد الصندوق الحالي',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '${_totalCashSYP.toStringAsFixed(0)} ل.س',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _totalCashSYP >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            '${_totalCashUSD.toStringAsFixed(2)} \$',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _totalCashUSD >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _journalEntries.isEmpty
                      ? const Center(child: Text('لا توجد حركات صندوق مسجلة'))
                      : ListView.builder(
                          itemCount: _journalEntries.length,
                          itemBuilder: (context, index) {
                            final item = _journalEntries[index];
                            final bool isPositive = (item['type'] == 'سند قبض' || item['type'] == 'إيداع');
                            final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                            final String currencySymbol = item['currency'] == 'ليرة سورية' ? 'ل.س' : '\$';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(
                                  isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text('${item['type']} - ${item['notes'] ?? 'بدون ملاحظات'}'),
                              subtitle: Text('التاريخ: ${item['date']}'),
                              trailing: Text(
                                '${isPositive ? "+" : "-"}${amount.toStringAsFixed(0)} $currencySymbol',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontSize: 15,
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
