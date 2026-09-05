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
  
  // متغيرا التاريخ للتصفية
  DateTime? _startDate;
  DateTime? _endDate;

  // قائمة الحركات المالية (تتضمن مبيعات، مشتريات، ودفعات للعملاء والموردين)
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '101',
      'title': 'فاتورة مبيعات #101',
      'date': DateTime(2026, 8, 15),
      'amount_syp': -350000.0,
      'amount_usd': 0.0,
      'type': 'invoice', // فاتورة
      'note': 'بضاعة بالآجل',
      'items': [
        {'name': 'منتج تجريبي 1', 'qty': 2, 'price': 100000.0},
        {'name': 'منتج تجريبي 2', 'qty': 1, 'price': 150000.0},
      ],
    },
    {
      'id': '102',
      'title': 'دفعة مقبوضة',
      'date': DateTime(2026, 8, 20),
      'amount_syp': 100000.0,
      'amount_usd': 0.0,
      'type': 'payment', // دفعة
      'note': 'دفعة تحت الحساب',
      'items': [],
    },
    {
      'id': '103',
      'title': 'فاتورة مشتريات #501',
      'date': DateTime(2026, 8, 25),
      'amount_syp': 500000.0,
      'amount_usd': 0.0,
      'type': 'purchase', // شراء من مورد
      'note': 'توريد مواد خام',
      'items': [
        {'name': 'مادة خام أ', 'qty': 10, 'price': 30000.0},
        {'name': 'مادة خام ب', 'qty': 4, 'price': 50000.0},
      ],
    },
    {
      'id': '104',
      'title': 'دفعة مسددة للمورد',
      'date': DateTime(2026, 9, 1),
      'amount_syp': 0.0,
      'amount_usd': -50.0,
      'type': 'supplier_payment', // تسديد للمورد
      'note': 'دفعة بالدولار حساب المورد',
      'items': [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentContact = widget.contact;
  }

  // دالة تصفية المعاملات حسب التاريخ المختار
  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((item) {
      final DateTime itemDate = item['date'] as DateTime;
      
      if (_startDate != null && itemDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && itemDate.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  // اختيار التاريخ
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // نافذة تفاصيل الفاتورة (مبيعات أو مشتريات)
  void _showInvoiceDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final bool isPurchase = item['type'] == 'purchase';
    final List<dynamic> items = item['items'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isPurchase ? 'تفاصيل فاتورة مشتريات' : 'تفاصيل فاتورة مبيعات',
          textAlign: TextAlign.right,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم الفاتورة: ${item['title']}'),
              Text('البيان / ملاحظات: ${item['note']}'),
              const SizedBox(height: 10),
              const Text('الأصناف والكميات:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              if (items.isEmpty)
                const Text('لا توجد تفاصيل أصناف مسجلة')
              else
                ...items.map((prod) {
                  final double price = prod['price'] as double;
                  final int qty = prod['qty'] as int;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${prod['name']} × $qty'),
                        Text('${(price * qty).toStringAsFixed(0)} ل.س'),
                      ],
                    ),
                  );
                }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المبلغ الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${(item['amount_syp'] as double).abs().toStringAsFixed(0)} ل.س',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPurchase ? Colors.orange.shade800 : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // نافذة تفاصيل الدفعة المالية (قبض من عميل / تسديد لمورد)
  void _showPaymentDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    final bool isSupplierPayment = item['type'] == 'supplier_payment';
    final double syp = item['amount_syp'] as double;
    final double usd = item['amount_usd'] as double;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isSupplierPayment ? 'إيصال دفعة مسددة للمورد' : 'إيصال دفعة مقبوضة من عميل',
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم العملية: #${item['id']}'),
            Text('البيان: ${item['note']}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المبلغ:'),
                Text(
                  syp != 0
                      ? '${syp.abs().toStringAsFixed(0)} ل.س'
                      : '${usd.abs().toStringAsFixed(2)} \$',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // نافذة تسجيل دفعة جديدة
  void _showAddPaymentDialog() {
    final sypController = TextEditingController(text: '0');
    final usdController = TextEditingController(text: '0');
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _currentContact.type == ContactType.client ? 'تسجيل دفعة من عميل' : 'تسجيل دفعة لمورد',
          textAlign: TextAlign.right,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sypController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ (ل.س)', prefixIcon: Icon(Icons.money)),
                textAlign: TextAlign.right,
              ),
              TextField(
                controller: usdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ (\$)', prefixIcon: Icon(Icons.attach_money)),
                textAlign: TextAlign.right,
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'ملاحظة / البيان', prefixIcon: Icon(Icons.note)),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              final syp = double.tryParse(sypController.text) ?? 0.0;
              final usd = double.tryParse(usdController.text) ?? 0.0;

              if (syp > 0 || usd > 0) {
                final bool isClient = _currentContact.type == ContactType.client;
                setState(() {
                  _transactions.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString().substring(7),
                    'title': isClient ? 'دفعة مقبوضة' : 'دفعة مسددة للمورد',
                    'date': DateTime.now(),
                    'amount_syp': isClient ? syp : -syp,
                    'amount_usd': isClient ? usd : -usd,
                    'type': isClient ? 'payment' : 'supplier_payment',
                    'note': noteController.text.trim(),
                    'items': [],
                  });

                  _currentContact = ContactModel(
                    id: _currentContact.id,
                    name: _currentContact.name,
                    phone: _currentContact.phone,
                    address: _currentContact.address,
                    type: _currentContact.type,
                    balanceSyp: _currentContact.balanceSyp + (isClient ? syp : -syp),
                    balanceUsd: _currentContact.balanceUsd + (isClient ? usd : -usd),
                  );
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
    final filteredList = _filteredTransactions;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('كشف حساب: ${_currentContact.name}'),
          backgroundColor: const Color(0xFF0D47A1),
        ),
        body: Column(
          children: [
            // ملخص الحساب
            Card(
              margin: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الهاتف: ${_currentContact.phone.isNotEmpty ? _currentContact.phone : "غير محدد"}'),
                        Chip(
                          label: Text(_currentContact.type == ContactType.client ? 'عميل' : 'مورد'),
                          backgroundColor: Colors.blue.shade100,
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBalanceBox('رصيد (ل.س)', _currentContact.balanceSyp, 'ل.س'),
                        _buildBalanceBox('رصيد (\$)', _currentContact.balanceUsd, '\$'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // شريط تصفية الفترة الزمنيّة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تصفية الكشف حسب الفترة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, true),
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            _startDate == null ? 'من تاريخ' : '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDate(context, false),
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            _endDate == null ? 'إلى تاريخ' : '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (_startDate != null || _endDate != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          tooltip: 'إلغاء التصفية',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('سجل الحركة المالية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            // قائمة الحركات المعتمدة مع إمكانية النقر للفتح
            Expanded(
              child: filteredList.isEmpty
                  ? const Center(child: Text('لا توجد حركات مسجلة في هذه الفترة'))
                  : ListView.builder(
                      itemCount: filteredList.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final String type = item['type'] as String;
                        final bool isPayment = (type == 'payment' || type == 'supplier_payment');
                        final double sypAmount = item['amount_syp'] as double;
                        final double usdAmount = item['amount_usd'] as double;
                        final DateTime date = item['date'] as DateTime;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: () {
                              if (isPayment) {
                                _showPaymentDetailsDialog(context, item);
                              } else {
                                _showInvoiceDetailsDialog(context, item);
                              }
                            },
                            leading: CircleAvatar(
                              backgroundColor: isPayment ? Colors.green.shade100 : Colors.red.shade100,
                              child: Icon(
                                isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isPayment ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                            title: Text(item['title'] as String),
                            subtitle: Text('التاريخ: ${date.year}-${date.month}-${date.day}\n${item['note']}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (sypAmount != 0)
                                  Text(
                                    '${sypAmount > 0 ? "+" : ""}${sypAmount.toStringAsFixed(0)} ل.س',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPayment ? Colors.green : Colors.red,
                                    ),
                                  ),
                                if (usdAmount != 0)
                                  Text(
                                    '${usdAmount > 0 ? "+" : ""}${usdAmount.toStringAsFixed(2)} \$',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPayment ? Colors.green : Colors.red,
                                    ),
                                  ),
                              ],
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
          icon: const Icon(Icons.add),
          label: const Text('تسجيل دفعة'),
        ),
      ),
    );
  }

  Widget _buildBalanceBox(String title, double amount, String unit) {
    final bool isDebt = amount < 0;
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '${amount.abs().toStringAsFixed(unit == '\$' ? 2 : 0)} $unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: amount == 0 ? Colors.grey : (isDebt ? Colors.red : Colors.green),
          ),
        ),
      ],
    );
  }
}
