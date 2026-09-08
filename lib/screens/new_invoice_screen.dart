import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  final dynamic existingInvoice;

  const NewInvoiceScreen({
    Key? key,
    this.existingInvoice,
  }) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // Enum/Types
  String _invoiceType = 'مبيعات';
  String _paymentMethod = 'نقدي';
  String _tradeType = 'مفرق';
  String _currency = 'ليرة سورية';

  // Controllers & Amounts
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  double _subTotal = 0.0;
  double _previousBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _paidAmountController.addListener(_onPaidAmountChanged);

    // إذا كانت هناك فاتورة سابقة ممررة للتعديل
    if (widget.existingInvoice != null) {
      // يمكنك هنا تعبئة البيانات من widget.existingInvoice
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double get _netTotal => _subTotal;

  double get _remainingBalance {
    double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return (_netTotal + _previousBalance) - paid;
  }

  void _updatePaymentLogic() {
    if (_paymentMethod == 'نقدي') {
      _paidAmountController.text = _netTotal.toStringAsFixed(2);
    }
  }

  void _onPaidAmountChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingInvoice != null ? 'تعديل فاتورة' : 'فاتورة جديدة'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToggleRow(
                title: 'نوع الفاتورة:',
                options: ['مبيعات', 'مشتريات'],
                selectedValue: _invoiceType,
                onSelected: (val) => setState(() => _invoiceType = val),
              ),
              const SizedBox(height: 12),

              _buildToggleRow(
                title: 'طريقة الدفع:',
                options: ['نقدي', 'آجل (دين)'],
                selectedValue: _paymentMethod,
                onSelected: (val) {
                  setState(() {
                    _paymentMethod = val;
                    _updatePaymentLogic();
                  });
                },
              ),
              const SizedBox(height: 12),

              _buildToggleRow(
                title: 'نوع التعامل:',
                options: ['مفرق', 'نصف جملة', 'جملة'],
                selectedValue: _tradeType,
                onSelected: (val) => setState(() => _tradeType = val),
              ),
              const SizedBox(height: 12),

              _buildToggleRow(
                title: 'عملة الفاتورة:',
                options: ['ليرة سورية', r'دولار ($)'], // تم إصلاح علامة الـ $
                selectedValue: _currency,
                onSelected: (val) => setState(() => _currency = val),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: 'اسم العميل',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _subTotal += 10000;
                    _updatePaymentLogic();
                  });
                },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text('إضافة منتج للفاتورة ($_tradeType)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildSummaryRow('المجموع الفرعي:', _subTotal),
              const Divider(),
              _buildSummaryRow('صافي الفاتورة:', _netTotal, isHighlight: true),
              const SizedBox(height: 16),

              Text(
                'رصيد سابق مترتب: ${_previousBalance.toStringAsFixed(1)} $_currencySymbol',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                enabled: _paymentMethod != 'نقدي',
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                  labelText: 'الدفعة المقبوضة ($_currencySymbol)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الرصيد الحالي المتبقي:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_remainingBalance.toStringAsFixed(1)} $_currencySymbol',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _remainingBalance > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _currencySymbol => _currency == 'ليرة سورية' ? 'ل.س' : r'$';

  Widget _buildToggleRow({
    required String title,
    required List<String> options,
    required String selectedValue,
    required Function(String) onSelected,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: options.map((opt) {
                bool isSelected = opt == selectedValue;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelected(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        opt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String title, double amount, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(1)} $_currencySymbol',
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
