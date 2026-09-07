import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({super.key, this.existingInvoice});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // خيارات الفاتورة
  bool _isSales = true; // true: مبيعات, false: مشتريات
  bool _isCash = true; // true: نقدي, false: آجل (دين)
  String _selectedCurrency = 'SYP'; // 'SYP' أو 'USD'

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController(text: '0');

  // مبالغ الحسابات
  double _subtotal = 0.0;
  double _previousBalance = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      final inv = widget.existingInvoice!;
      _customerController.text = inv['customer'] ?? '';
      _isSales = inv['isSales'] ?? true;
      _isCash = inv['isCash'] ?? true;
      _selectedCurrency = inv['currency'] ?? 'SYP';
      _subtotal = (inv['subtotal'] as num?)?.toDouble() ?? 0.0;
      _previousBalance = (inv['previousBalance'] as num?)?.toDouble() ?? 0.0;
      _paidAmountController.text = ((inv['paidAmount'] as num?)?.toDouble() ?? 0.0).toString();
    }
  }

  String get _currencySymbol => _selectedCurrency == 'USD' ? '\$' : 'ل.س';

  double get _netTotal => _subtotal;

  double get _paidAmount => double.tryParse(_paidAmountController.text.trim()) ?? 0.0;

  double get _remainingBalance => (_netTotal + _previousBalance) - _paidAmount;

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
          title: Text(
            widget.existingInvoice != null ? 'تعديل فاتورة' : 'فاتورة جديدة',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // خيارات الفاتورة العليا (النوع، طريقة الدفع، والعملة)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // نوع الفاتورة: مبيعات / مشتريات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نوع الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('مبيعات')),
                            ButtonSegment(value: false, label: Text('مشتريات')),
                          ],
                          selected: {_isSales},
                          onSelectionChanged: (Set<bool> newSelection) {
                            setState(() => _isSales = newSelection.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // طريقة الدفع: نقدي / آجل
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('نقدي')),
                            ButtonSegment(value: false, label: Text('آجل (دين)')),
                          ],
                          selected: {_isCash},
                          onSelectionChanged: (Set<bool> newSelection) {
                            setState(() => _isCash = newSelection.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // عملة الفاتورة: ليرة سورية / دولار
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('عملة الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'SYP', label: Text('ليرة سورية (ل.س)')),
                            ButtonSegment(value: 'USD', label: Text('دولار (\$)')),
                          ],
                          selected: {_selectedCurrency},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() => _selectedCurrency = newSelection.first);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // اسم العميل / المورد
                    TextField(
                      controller: _customerController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        hintText: _isSales ? 'اسم العميل' : 'اسم المورد',
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // زر إضافة منتج
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0083B0), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0083B0)),
                  label: const Text(
                    'إضافة منتج للفاتورة',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0083B0), fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // المجموع والصافي
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
                        const Text('المجموع الفرعي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${_subtotal.toStringAsFixed(1)} $_currencySymbol',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          '${_netTotal.toStringAsFixed(1)} $_currencySymbol',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // الرصيد السابق والدفعة المقبوضة
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
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.history, size: 18, color: Colors.grey),
                            SizedBox(width: 6),
                            Text('رصيد سابق مترتب:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${_previousBalance.toStringAsFixed(1)} $_currencySymbol',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(height: 12),

                    // حقل الدفعة
                    TextField(
                      controller: _paidAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: _isSales ? 'الدفعة المقبوضة ($_currencySymbol)' : 'الدفعة المدفوعة ($_currencySymbol)',
                        prefixIcon: const Icon(Icons.money_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الرصيد الحالي المتبقي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '${_remainingBalance.toStringAsFixed(1)} $_currencySymbol',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _remainingBalance > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // زر حفظ الفاتورة
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0083B0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: Text(
                    widget.existingInvoice != null ? 'تحديث الفاتورة' : 'حفظ الفاتورة',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
