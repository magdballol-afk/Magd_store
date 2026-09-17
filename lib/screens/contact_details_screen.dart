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
    _currentSYP = widget.contact.balanceSyr;
    _currentUSD = widget.contact.balanceUsd;
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
        'journal_entries',
        where: 'description LIKE ?',
        whereArgs: ['%${widget.contact.name}%'],
      );

      List<Map<String, dynamic>> combined = [];

      for (var inv in invoices) {
        combined.add({
          'date': inv['created_at'] ?? '',
          'title': 'فاتورة مبيعات',
          'amount': (inv['net_total'] as num?)?.toDouble() ?? 0.0,
          'currency': inv['currency'] ?? 'ليرة سورية',
          'isDebit': true, // الفاتورة تزيد على العميل
          'subtitle': 'فاتورة رقم #${inv['id']}',
        });
      }

      for (var cash in cashEntries) {
        final String type = (cash['type'] ?? '').toString();
        final bool isDebit = type == 'دفعة' || type == 'سند دفع';

        combined.add({
          'date': cash['date'] ?? '',
          'title': cash['type'] ?? 'دفعة مالية',
          'amount': (cash['amount'] as num?)?.toDouble() ?? 0.0,
          'currency': 'ليرة سورية',
          'isDebit': isDebit,
          'subtitle': cash['description'] ?? 'سند صندوق',
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
    String paymentType = 'سند قبض';

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
                    await db.insert('journal_entries', {
                      'description': '${notesController.text.trim()} - العميل: ${widget.contact.name}',
                      'amount': amount,
                      'type': paymentType,
                      'date': DateTime.now().toIso8601String().split('T').first,
                    });

                    // تحديث رصيد العميل بناءً على نوع الحركة والعملة
                    double sypChange = 0.0;
                    double usdChange = 0.0;

                    double adjustment = (paymentType == 'سند قبض') ? -amount : amount;

                    if (selectedCurrency == 'ليرة سورية') {
                      sypChange = adjustment;
                    } else {
                      usdChange = adjustment;
                    }

                    if (widget.contact.id != null) {
                      if (selectedCurrency == 'ليرة سورية') {
                        await db.rawUpdate(
                          'UPDATE contacts SET balance_syr = balance_syr + ?, balance = balance + ? WHERE id = ?',
                          [sypChange, sypChange, widget.contact.id],
                        );
                      } else {
                        await db.rawUpdate(
                          'UPDATE contacts SET balance_usd = balance_usd + ? WHERE id = ?',
                          [usdChange, widget.contact.id],
                        );
                      }
                    }

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
                const Text(
                  'رصيد الحساب (عميل)',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
              label: const Text('قبض دفعة من العميل'),
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
