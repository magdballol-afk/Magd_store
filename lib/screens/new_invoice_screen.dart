import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String _invoiceType = 'فاتورة مبيعات'; // أو 'فاتورة مشتريات'
  String _currency = 'ليرة سورية';
  bool _isDeferred = false; // هل الفاتورة آجلة (على الحساب)؟

  ContactModel? _selectedContact;
  List<ContactModel> _contactsList = [];
  bool _isLoadingContacts = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final rawData = await DatabaseHelper.instance.getParties();
    setState(() {
      _contactsList = rawData.map((map) {
        return ContactModel(
          id: map['id'].toString(),
          name: map['name'] ?? '',
          phone: map['phone'] ?? '',
          address: map['address'] ?? '',
          type: map['type'] ?? 'عميل',
          balanceSYP: (map['balance_syp'] as num?)?.toDouble() ?? 0.0,
          balanceUSD: (map['balance_usd'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
      _isLoadingContacts = false;
    });
  }

  Future<void> _saveInvoice() async {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح')),
      );
      return;
    }

    if (_isDeferred && _selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد العميل/المورد للفواتير الآجلة')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;

    // 1. إضافة الفاتورة في جدول الفواتير
    final int invoiceId = await db.insert('invoices', {
      'party_id': _selectedContact?.id,
      'type': _invoiceType,
      'total_amount': amount,
      'currency': _currency,
      'is_deferred': _isDeferred ? 1 : 0,
      'notes': _notesController.text.trim(),
      'date': DateTime.now().toIso8601String().split('T').first,
    });

    // 2. إذا كانت الفاتورة آجلة أو مرتبطة بعميل/مورد، نقوم بتحديث رصيد الحساب
    if (_selectedContact != null && _isDeferred) {
      double sypChange = 0.0;
      double usdChange = 0.0;

      // المبيعات الآجلة تزيد الدين على العميل (+)
      // المشتريات الآجلة تزيد الدين للمورد (-)
      double balanceImpact = (_invoiceType == 'فاتورة مبيعات') ? amount : -amount;

      if (_currency == 'ليرة سورية') {
        sypChange = balanceImpact;
      } else {
        usdChange = balanceImpact;
      }

      await DatabaseHelper.instance.updatePartyBalance(
        int.parse(_selectedContact!.id),
        sypChange,
        usdChange,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الفاتورة رقم #$invoiceId بنجاح')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع الفاتورة
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'فاتورة مبيعات', label: Text('فاتورة مبيعات')),
                ButtonSegment(value: 'فاتورة مشتريات', label: Text('فاتورة مشتريات')),
              ],
              selected: {_invoiceType},
              onSelectionChanged: (val) {
                setState(() => _invoiceType = val.first);
              },
            ),
            const SizedBox(height: 16),

            // نوع الدفع: نقداً أم على الحساب
            SwitchListTile(
              title: const Text('فاتورة آجلة (على الحساب)'),
              value: _isDeferred,
              onChanged: (val) => setState(() => _isDeferred = val),
            ),
            const SizedBox(height: 12),

            // قائمة اختيار العميل / المورد
            _isLoadingContacts
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<ContactModel>(
                    value: _selectedContact,
                    decoration: const InputDecoration(
                      labelText: 'العميل / المورد',
                      border: OutlineInputBorder(),
                    ),
                    items: _contactsList.map((contact) {
                      return DropdownMenuItem(
                        value: contact,
                        child: Text('${contact.name} (${contact.type})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedContact = val),
                  ),
            const SizedBox(height: 16),

            // العملة والمبلغ
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ الإجمالي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ليرة سورية', child: Text('ل.س')),
                      DropdownMenuItem(value: 'دولار (\$)', child: Text('\$')),
                    ],
                    onChanged: (val) => setState(() => _currency = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ملاحظات
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الفاتورة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveInvoice,
                child: const Text('حفظ الفاتورة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
