import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../database/database_helper.dart';

class ContactDetailsScreen extends StatefulWidget {
  final ContactModel contact;

  const ContactDetailsScreen({super.key, required this.contact});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  late double _currentSYP;
  late double _currentUSD;

  @override
  void initState() {
    super.initState();
    _currentSYP = widget.contact.balanceSYP;
    _currentUSD = widget.contact.balanceUSD;
    _loadAccountStatement();
  }

  // 1. جلب الحركات المالية من SQLite (الفواتير وسندات الصندوق)
  Future<void> _loadAccountStatement() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      // جلب الفواتير المرتبطة بهذا العميل/المورد
      final invoices = await db.query(
        'invoices',
        where: 'party_id = ?',
        whereArgs: [widget.contact.id],
      );

      // جلب حركات دفتر الصندوق المرتبطة بهذا العميل/المورد
      final cashEntries = await db.query(
        'cash_journal',
        where: 'party_id = ?',
        whereArgs: [widget.contact.id],
      );

      List<Map<String, dynamic>> combined = [];

      for (var inv in invoices) {
        combined.add({
          'date': inv['date'] ?? '',
          'title': inv['type'] ?? 'فاتورة',
          'amount': (inv['total_amount'] as num?)?.toDouble() ?? 0.0,
          'currency': inv['currency'] ?? 'ليرة سورية',
          'isDebit': inv['type'] == 'فاتورة مبيعات', // المبيعات تزيد على العميل
          'subtitle': 'فاتورة رقم #${inv['id']}',
        });
      }

      for (var cash in cashEntries) {
        combined.add({
          'date': cash['date'] ?? '',
          'title': cash['type'] ?? 'دفعة مالية',
          'amount': (cash['amount'] as num?)?.toDouble() ?? 0.0,
          'currency': cash['currency'] ?? 'ليرة سورية',
          'isDebit': cash['type'] == 'سند دفع', // الدفع يقلل الدين
          'subtitle': cash['notes'] ?? 'سند صندوق',
        });
      }

      // ترتيب الحركات زمنيًا من الأحدث للأقدم
      combined.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      setState(() {
        _transactions = combined;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 2. إجراء مكالمة هاتفية للعميل/المورد
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // 3. نافذة إظهار إمكانية تسجيل دفعة/قبض سريع
  void _showPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCurrency = 'ليرة سورية';
    String paymentType = widget.contact.type == 'عميل' ? 'سند قبض' : 'سند دفع';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulWidget(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('تسجيل $paymentType جديد'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      items: const [
                        DropdownMenuItem(value: 'ليرة سورية', child: Text('ليرة سورية')),
                        DropdownMenuItem(value: 'دولار (\$)', child: Text('دولار (\$)')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedCurrency = val!),
                      decoration: const InputDecoration(labelText: 'العملة', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'ملاحظات / البيان', border: OutlineInputBorder()),
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

                    // إضافة الحركة إلى دفتر الصندوق
                    await db.insert('cash_journal', {
                      'party_id': widget.contact.id,
                      'type': paymentType,
                      'amount': amount,
                      'currency': selectedCurrency,
                      'notes': notesController.text.trim(),
                      'date': DateTime.now().toIso8601String().split('T').first,
                    });

                    // تحديث رصيد العميل بناءً على نوع الحركة والعملة
                    double sypChange = 0.0;
                    double usdChange = 0.0;

                    // سند القبض يقلل من دين العميل، وسند الدفع يقلل من حساب المورد
                    double adjustment = (paymentType == 'سند قبض') ? -amount : amount;

                    if (selectedCurrency == 'ليرة سورية') {
                      sypChange = adjustment;
                    } else {
                      usdChange = adjustment;
                    }

                    await DatabaseHelper.instance.updatePartyBalance(
                      int.parse(widget.contact.id),
                      sypChange,
                      usdChange,
                    );

                    setState(() {
                      _currentSYP += sypChange;
                      _currentUSD += usdChange;
                    });

                    if (context.mounted) Navigator.pop(context);
                    _loadAccountStatement();
                  },
                  child: const Text('حفظ الدفعة'),
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
        title: Text(widget.contact.name),
        actions: [
          if (widget.contact.phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () => _makePhoneCall(widget.contact.phone),
            ),
        ],
      ),
      body: Column(
        children: [
          // بطاقة ملخص أرصدة العميل/المورد
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0052CC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'رصيد الحساب (${widget.contact.type})',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('بالليرة السورية', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '$_currentSYP ل.س',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white30),
                    Column(
                      children: [
                        const Text('بالدولار الأمريكي', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '$_currentUSD \$',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // زر الدفع السريع
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _showPaymentDialog,
              icon: const Icon(Icons.add_card),
              label: Text(widget.contact.type == 'عميل' ? 'قبض دفعة من العميل' : 'تسديد دفعة للمورد'),
            ),
          ),
          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'كشف الحساب (السجل المالي):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          // قائمة الحركات المالية
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(child: Text('لا توجد حركات مالية مسجلة بعد'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isDebit = tx['isDebit'] as bool;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDebit ? Colors.red.shade100 : Colors.green.shade100,
                                child: Icon(
                                  isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isDebit ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${tx['subtitle']}\nالتاريخ: ${tx['date']}'),
                              isThreeLine: true,
                              trailing: Text(
                                '${tx['amount']} ${tx['currency']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDebit ? Colors.red : Colors.green,
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
