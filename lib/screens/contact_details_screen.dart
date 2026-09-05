import 'package:flutter/material.dart';
import '../models/contact_model.dart';

class ContactDetailsScreen extends StatefulWidget {
  final ContactModel contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  late ContactModel _currentContact;

  // قائمة محاكاة للحركات المالية الخاصة بالعميل/المورد
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '101',
      'title': 'فاتورة مبيعات #1001',
      'date': '2026-09-01',
      'type': 'invoice',
      'amount_syp': -150000.0,
      'amount_usd': 0.0,
    },
    {
      'id': '102',
      'title': 'دفعة نقدية مقبوضة',
      'date': '2026-09-03',
      'type': 'payment',
      'amount_syp': 50000.0,
      'amount_usd': 0.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentContact = widget.contact;
  }

  // نافذة تسجيل دفعة مالية جديدة (قبض / صرف)
  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCurrency = 'SYP';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _currentContact.type == ContactType.client
              ? 'قبض دفعة من عميل'
              : 'دفع مبلغ لمورد',
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              items: const [
                DropdownMenuItem(value: 'SYP', child: Text('ليرة سورية (SYP)')),
                DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
              ],
              onChanged: (val) => selectedCurrency = val!,
              decoration: const InputDecoration(labelText: 'العملة'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                prefixIcon: Icon(Icons.attach_money),
              ),
              textAlign: TextAlign.right,
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات / البيان (اختياري)',
                prefixIcon: Icon(Icons.note),
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                setState(() {
                  _transactions.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': notesController.text.trim().isNotEmpty
                        ? notesController.text.trim()
                        : (_currentContact.type == ContactType.client ? 'دفعة مقبوضة' : 'دفعة مدفوعة'),
                    'date': DateTime.now().toString().split(' ')[0],
                    'type': 'payment',
                    'amount_syp': selectedCurrency == 'SYP' ? amount : 0.0,
                    'amount_usd': selectedCurrency == 'USD' ? amount : 0.0,
                  });

                  if (selectedCurrency == 'SYP') {
                    _currentContact = _currentContact.copyWith(
                      balanceSyp: _currentContact.balanceSyp + amount,
                    );
                  } else {
                    _currentContact = _currentContact.copyWith(
                      balanceUsd: _currentContact.balanceUsd + amount,
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ الدفعة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('كشف حساب: ${_currentContact.name}'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
        body: Column(
          children: [
            // بطاقة الترويسة والملخص المالي
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentContact.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('هاتف: ${_currentContact.phone}'),
                        ],
                      ),
                      Chip(
                        label: Text(
                          _currentContact.type == ContactType.client ? 'عميل' : 'مورد',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF0D47A1),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBalanceBox(
                        title: 'الرصيد (ل.س)',
                        amount: _currentContact.balanceSyp,
                        currency: 'ل.س',
                      ),
                      _buildBalanceBox(
                        title: 'الرصيد (\$)',
                        amount: _currentContact.balanceUsd,
                        currency: '\$',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'سجل الفواتير والدفعات السابقة:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (context, index) {
                  final item = _transactions[index];
                  final bool isPayment = item['type'] == 'payment';
                  final double sypAmount = item['amount_syp'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPayment ? Colors.green.shade100 : Colors.red.shade100,
                        child: Icon(
                          isPayment ? Icons.arrow_downward : Icons.receipt_long,
                          color: isPayment ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                      title: Text(item['title']),
                      subtitle: Text('التاريخ: ${item['date']}'),
                      trailing: Text(
                        '${sypAmount > 0 ? "+" : ""}${sypAmount.toStringAsFixed(0)} ل.س',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPayment ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddPaymentDialog,
          backgroundColor: Colors.green.shade700,
          icon: const Icon(Icons.add_card),
          label: Text(_currentContact.type == ContactType.client ? 'قبض دفعة' : 'صرف دفعة'),
        ),
      ),
    );
  }

  Widget _buildBalanceBox({required String title, required double amount, required String currency}) {
    final bool isDebt = amount < 0;
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '${amount.abs().toStringAsFixed(0)} $currency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: amount == 0 ? Colors.black : (isDebt ? Colors.red : Colors.green),
          ),
        ),
      ],
    );
  }
}
