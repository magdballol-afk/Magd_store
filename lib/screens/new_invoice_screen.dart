import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  String _paymentType = 'آجل (دين)'; // 'نقدي' أو 'آجل (دين)'
  String _dealType = 'مفرق'; // 'مفرق'، 'نصف جملة'، 'جملة'
  String _currency = 'ليرة سورية'; // 'ليرة سورية' أو 'دولار ($)'

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  // قاعدة بيانات تجريبية للعملاء (يمكن استبدالها بربط من قاعدة البيانات الحقيقية)
  final List<Map<String, dynamic>> _customersList = [
    {'name': 'محمد أحمد العلي', 'phone': '0911111111', 'previousBalance': 15000.0},
    {'name': 'محمود سليمان', 'phone': '0922222222', 'previousBalance': 0.0},
    {'name': 'أحمد إبراهيم', 'phone': '0933333333', 'previousBalance': 45000.0},
    {'name': 'خالد السعيد', 'phone': '0944444444', 'previousBalance': 12000.0},
    {'name': 'سامر خليل', 'phone': '0955555555', 'previousBalance': 0.0},
  ];

  // قائمة المنتجات داخل الفاتورة
  List<Map<String, dynamic>> _invoiceItems = [
    {
      'name': 'شامبو بانتين 400 مل',
      'quantity': 1,
      'price': 12500.0,
      'total': 12500.0,
    },
  ];

  double _previousBalance = 0.0; // الرصيد السابق للعميل المختار

  // حساب المجموع الفرعي
  double get _subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  // حساب صافي الفاتورة
  double get _netTotal => _subtotal;

  // حساب الدفعة المقبوضة
  double get _paidAmount {
    if (_paymentType == 'نقدي') {
      return _netTotal;
    }
    return double.tryParse(_paidAmountController.text) ?? 0.0;
  }

  // حساب الرصيد المتبقي
  double get _remainingBalance {
    if (_paymentType == 'نقدي') {
      return 0.0;
    }
    return (_netTotal + _previousBalance) - _paidAmount;
  }

  // إعادة ضبط الواجهة لإنشاء فاتورة جديدة
  void _resetForm() {
    setState(() {
      _paymentType = 'آجل (دين)';
      _dealType = 'مفرق';
      _currency = 'ليرة سورية';
      _customerNameController.clear();
      _paidAmountController.clear();
      _previousBalance = 0.0;
      _invoiceItems.clear();
    });
  }

  // دالة حفظ الفاتورة مع التحقق من الشروط
  void _saveInvoice() {
    // 1. التحقق من وجود منتجات
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إضافة منتج واحد على الأقل للفاتورة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. التحقق من اسم العميل في حال كانت الفاتورة آجل (دين)
    if (_paymentType == 'آجل (دين)' && _customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال/اختيار اسم العميل لتسجيل الفاتورة الآجلة!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 3. تأكيد الحفظ وإعادة ضبط الشاشة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الفاتورة بنجاح'),
        backgroundColor: Colors.green,
      ),
    );

    // الانتقال للوضع الأصلي وتصفير البيانات لإنشاء فاتورة جديدة
    _resetForm();
  }

  Widget _buildToggleOption<T>({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0277BD) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _currency == 'ليرة سورية' ? 'ل.س' : '\$';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'فاتورة جديدة',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // خيارات طريقة الدفع
            Row(
              children: [
                _buildToggleOption(
                  label: 'آجل (دين)',
                  isSelected: _paymentType == 'آجل (دين)',
                  onTap: () => setState(() => _paymentType = 'آجل (دين)'),
                ),
                const SizedBox(width: 8),
                _buildToggleOption(
                  label: 'نقدي',
                  isSelected: _paymentType == 'نقدي',
                  onTap: () {
                    setState(() {
                      _paymentType = 'نقدي';
                      _paidAmountController.clear();
                    });
                  },
                ),
                const SizedBox(width: 12),
                const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // خيارات نوع التعامل
            Row(
              children: [
                _buildToggleOption(
                  label: 'جملة',
                  isSelected: _dealType == 'جملة',
                  onTap: () => setState(() => _dealType = 'جملة'),
                ),
                const SizedBox(width: 6),
                _buildToggleOption(
                  label: 'نصف جملة',
                  isSelected: _dealType == 'نصف جملة',
                  onTap: () => setState(() => _dealType = 'نصف جملة'),
                ),
                const SizedBox(width: 6),
                _buildToggleOption(
                  label: 'مفرق',
                  isSelected: _dealType == 'مفرق',
                  onTap: () => setState(() => _dealType = 'مفرق'),
                ),
                const SizedBox(width: 12),
                const Text('نوع التعامل:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // خيارات عملة الفاتورة
            Row(
              children: [
                _buildToggleOption(
                  label: 'دولار (\$)',
                  isSelected: _currency == 'دولار (\$)',
                  onTap: () => setState(() => _currency = 'دولار (\$)'),
                ),
                const SizedBox(width: 8),
                _buildToggleOption(
                  label: 'ليرة سورية',
                  isSelected: _currency == 'ليرة سورية',
                  onTap: () => setState(() => _currency = 'ليرة سورية'),
                ),
                const SizedBox(width: 12),
                const Text('عملة الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // حقل إدخال اسم العميل المتقدم مع خاصية الاقتراح التلقائي والبحث
            RawAutocomplete<Map<String, dynamic>>(
              textEditingController: _customerNameController,
              focusNode: FocusNode(),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
                return _customersList.where((customer) {
                  final name = customer['name'].toString().toLowerCase();
                  final phone = customer['phone'].toString();
                  final query = textEditingValue.text.toLowerCase();
                  return name.contains(query) || phone.contains(query);
                });
              },
              displayStringForOption: (Map<String, dynamic> option) => option['name'],
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  _customerNameController.text = selection['name'];
                  _previousBalance = (selection['previousBalance'] as double);
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث أو أدخل اسم العميل...',
                    prefixIcon: const Icon(Icons.person_search, color: Color(0xFF0277BD)),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _previousBalance = 0.0;
                              });
                            },
                          )
                        : null,
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      maxHeight: 200,
                      color: Colors.white,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(
                              option['name'],
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'الهاتف: ${option['phone']} | رصيد سابق: ${option['previousBalance']} $currencySymbol',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // زر إضافة منتج
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  side: const BorderSide(color: Color(0xFF0277BD)),
                ),
                onPressed: () {
                  setState(() {
                    _invoiceItems.add({
                      'name': 'منتج جديد',
                      'quantity': 1,
                      'price': 5000.0,
                      'total': 5000.0,
                    });
                  });
                },
                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0277BD)),
                label: Text(
                  'إضافة منتج للفاتورة ($_dealType)',
                  style: const TextStyle(color: Color(0xFF0277BD), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              ':المنتجات المضافة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // قائمة المنتجات
            if (_invoiceItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('لم يتم إضافة أي منتج بعد', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._invoiceItems.asMap().entries.map((entry) {
                int index = entry.key;
                var item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _invoiceItems.removeAt(index);
                          });
                        },
                      ),
                      Text('${item['total']} $currencySymbol',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${item['quantity']} × ${item['price']} $currencySymbol',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const Divider(height: 24),

            // تفاصيل الحساب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_subtotal $currencySymbol', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text(':المجموع الفرعي', style: TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_netTotal $currencySymbol',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                const Text(':صافي الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_previousBalance $currencySymbol', style: const TextStyle(color: Colors.grey)),
                const Text(':رصيد سابق مترتب', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // حقل الدفعة المقبوضة (مفعل عند الدفع الآجل)
            if (_paymentType == 'آجل (دين)') ...[
              TextField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'الدفعة المقبوضة ($currencySymbol)',
                  prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // الرصيد المتبقي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_remainingBalance $currencySymbol',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _remainingBalance > 0 ? Colors.red : Colors.green,
                  ),
                ),
                const Text(':الرصيد الحالي المتبقي', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 24),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0277BD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _saveInvoice,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'حفظ الفاتورة',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
