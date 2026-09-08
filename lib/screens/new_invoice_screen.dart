import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // Enum/Types
  String _invoiceType = 'مبيعات'; // مبيعات / مشتريات
  String _paymentMethod = 'نقدي'; // نقدي / آجل (دين)
  String _tradeType = 'مفرق'; // مفرق / نصف جملة / جملة
  String _currency = 'ليرة سورية'; // ليرة سورية / دولار ($)

  // Controllers & Amounts
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  double _subTotal = 0.0;
  double _previousBalance = 0.0; // رصيد سابق مترتب

  @override
  void initState() {
    super.initState();
    _paidAmountController.addListener(_onPaidAmountChanged);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  // حساب صافي الفاتورة
  double get _netTotal => _subTotal;

  // حساب الرصيد الحالي المتبقي
  double get _remainingBalance {
    double paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    return (_netTotal + _previousBalance) - paid;
  }

  // تحديث الدفعة المقبوضة تلقائياً عند تغيير طريقة الدفع أو إجمالي الفاتورة
  void _updatePaymentLogic() {
    if (_paymentMethod == 'نقدي') {
      _paidAmountController.text = _netTotal.toStringAsFixed(2);
    }
  }

  void _onPaidAmountChanged() {
    setState(() {}); // إعادة بناء الواجهة لتحديث الرصيد المتبقي
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. خيارات نوع الفاتورة وطريقة الدفع
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
                options: ['ليرة سورية', 'دولار ($)'],
                selectedValue: _currency,
                onSelected: (val) => setState(() => _currency = val),
              ),
              const SizedBox(height: 16),

              // 2. حقل اسم العميل
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

              // 3. زر إضافة منتج
              OutlinedButton.icon(
                onPressed: () {
                  // محاكاة إضافة منتج بقيمة 10000 لتجربة المنطق
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

              // 4. عرض المجاميع
              _buildSummaryRow('المجموع الفرعي:', _subTotal),
              const Divider(),
              _buildSummaryRow('صافي الفاتورة:', _netTotal, isHighlight: true),
              const SizedBox(height: 16),

              // 5. الرصيد السابق والدفعات
              Text(
                'رصيد سابق مترتب: ${_previousBalance.toStringAsFixed(1)} $_currencySymbol',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // حقل الدفعة المقبوضة
              TextField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                enabled: _paymentMethod != 'نقدي', // تعطيل التعديل اليدوي إذا كانت الفاتورة نقدية
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                  labelText: 'الدفعة المقبوضة ($_currencySymbol)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 6. الرصيد الحالي المتبقي
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

  String get _currencySymbol => _currency == 'ليرة سورية' ? 'ل.س' : '\$';

  // WIDGETS HELPER: أزرار التبديل الاختيارية
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

  // WIDGETS HELPER: صفوف المجاميع
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
