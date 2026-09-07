import 'package:flutter/material.dart';

class CashJournalScreen extends StatefulWidget {
  const CashJournalScreen({super.key});

  @override
  State<CashJournalScreen> createState() => _CashJournalScreenState();
}

class _CashJournalScreenState extends State<CashJournalScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isPayment = true; // true: مدفوعات, false: مقبوضات

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // متغير لتحديد الحركة المراد تعديلها (null يعني إضافة جديدة)
  int? _editingIndex;

  // قائمة وهمية لحركات اليوم للتجربة والتفاعل
  final List<Map<String, dynamic>> _movements = [
    {
      'account': 'مجد',
      'amount': 108.0,
      'isPayment': true,
      'description': 'بدون بيان',
    },
  ];

  void _saveOrUpdateMovement() {
    final account = _accountController.text.trim();
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (account.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الحساب والمبلغ')),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;

    setState(() {
      if (_editingIndex != null) {
        // تعديل حركة موجودة
        _movements[_editingIndex!] = {
          'account': account,
          'amount': amount,
          'isPayment': _isPayment,
          'description': description.isEmpty ? 'بدون بيان' : description,
        };
        _editingIndex = null;
      } else {
        // إضافة حركة جديدة
        _movements.add({
          'account': account,
          'amount': amount,
          'isPayment': _isPayment,
          'description': description.isEmpty ? 'بدون بيان' : description,
        });
      }

      _accountController.clear();
      _amountController.clear();
      _descriptionController.clear();
    });
  }

  void _startEditing(int index) {
    final item = _movements[index];
    setState(() {
      _editingIndex = index;
      _isPayment = item['isPayment'];
      _accountController.text = item['account'];
      _amountController.text = item['amount'].toString();
      _descriptionController.text = item['description'] == 'بدون بيان' ? '' : item['description'];
    });
  }

  void _deleteMovement(int index) {
    setState(() {
      if (_editingIndex == index) {
        _editingIndex = null;
        _accountController.clear();
        _amountController.clear();
        _descriptionController.clear();
      }
      _movements.removeAt(index);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
      _accountController.clear();
      _amountController.clear();
      _descriptionController.clear();
    });
  }

  double get _totalReceipts => _movements
      .where((m) => m['isPayment'] == false)
      .fold(0.0, (sum, item) => sum + (item['amount'] as double));

  double get _totalPayments => _movements
      .where((m) => m['isPayment'] == true)
      .fold(0.0, (sum, item) => sum + (item['amount'] as double));

  double get _netAmount => _totalReceipts - _totalPayments;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF0083B0),
          title: const Text(
            'إدخال وتعديل يومية صندوق',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اختيار التاريخ
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF0083B0)),
                          const SizedBox(width: 8),
                          Text(
                            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // نموذج الإدخال والتعديل
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: _editingIndex != null ? Border.all(color: Colors.orange, width: 2) : null,
                ),
                child: Column(
                  children: [
                    if (_editingIndex != null)
                      Padding(
                        padding: const EdgeInsets.bottom(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'جاري تعديل حركة...',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            TextButton.icon(
                              onPressed: _cancelEditing,
                              icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                              label: const Text('إلغاء التعديل', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            )
                          ],
                        ),
                      ),
                    
                    // أزرار نوع الحركة (مقبوضات / مدفوعات)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPayment = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isPayment ? Colors.green.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: !_isPayment ? Colors.green : Colors.transparent),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward, color: !_isPayment ? Colors.green : Colors.grey, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'مقبوضات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_isPayment ? Colors.green : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPayment = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isPayment ? Colors.red.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _isPayment ? Colors.red : Colors.transparent),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward, color: _isPayment ? Colors.red : Colors.grey, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'مدفوعات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isPayment ? Colors.red : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // حقل اسم الحساب
                    TextField(
                      controller: _accountController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                        hintText: 'اسم الحساب (العميل / المورد / ...)',
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // حقل المبلغ
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.attach_money, size: 20),
                        hintText: 'المبلغ',
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // حقل البيان
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                        hintText: 'البيان / ملاحظات',
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // زر الإضافة / التحديث
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _editingIndex != null ? Colors.orange : const Color(0xFF0083B0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _saveOrUpdateMovement,
                        icon: Icon(_editingIndex != null ? Icons.check : Icons.add_circle_outline, color: Colors.white),
                        label: Text(
                          _editingIndex != null ? 'تحديث الحركة' : 'إضافة الحركة الصندوقية',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'حركات اليوم المسجلة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),

              // قائمة الحركات المسجلة
              _movements.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('لا توجد حركات مسجلة لهذا اليوم', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _movements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _movements[index];
                        final isPayment = item['isPayment'] as bool;
                        final amount = item['amount'] as double;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['account'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['description'],
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${isPayment ? '-' : '+'}${amount.toStringAsFixed(1)} ل.س",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isPayment ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _startEditing(index),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () => _deleteMovement(index),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 20),

              // ملخص المبالغ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المقبوضات:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('${_totalReceipts.toStringAsFixed(1)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المدفوعات:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('${_totalPayments.toStringAsFixed(1)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي حركة اليوم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          '${_netAmount.toStringAsFixed(1)} ل.س',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _netAmount >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
