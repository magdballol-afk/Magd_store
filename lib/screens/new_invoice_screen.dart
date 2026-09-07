import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? existingInvoice;

  const NewInvoiceScreen({Key? key, this.existingInvoice}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  bool isEditing = false;
  bool isNewInvoice = true;

  String invoiceType = 'مبيعات';
  String paymentType = 'نقدي';
  String dealingType = 'مفرق';

  late TextEditingController customerController;
  late TextEditingController exchangeRateController;
  late TextEditingController globalDiscountController;
  
  // حقل الدفعة فقط هو حقل إدخال يدوي
  late TextEditingController paidAmountController;

  // قيمة الرصيد السابق المترتب على الزبون (تُجلب تلقائياً من قاعدة البيانات)
  double previousBalance = 0.0;

  List<Map<String, dynamic>> invoiceItems = [];
  List<Map<String, dynamic>> backupItems = [];

  // محاكاة لبيانات العملاء وأرصدتهم المترتبة عليهم من قاعدة البيانات
  final Map<String, double> customerBalancesFromDB = {
    'أحمد علي': 25000.0,
    'محمد خالد': 50000.0,
    'سامر محمود': 0.0,
  };

  final List<Map<String, dynamic>> availableProducts = [
    {'name': 'شامبو بانتين 400 مل', 'price': 12500.0},
    {'name': 'معجون أسنان كولجيت', 'price': 8000.0},
    {'name': 'صابون دوف 100غ', 'price': 4500.0},
    {'name': 'مناديل فاين 500 منديل', 'price': 15000.0},
  ];

  @override
  void initState() {
    super.initState();
    isNewInvoice = widget.existingInvoice == null;
    isEditing = isNewInvoice;

    final inv = widget.existingInvoice;
    customerController = TextEditingController(text: inv != null ? inv['customer'] : '');
    exchangeRateController = TextEditingController(text: '15000');
    globalDiscountController = TextEditingController(text: '0');

    paidAmountController = TextEditingController(
      text: inv != null ? (inv['paidAmount']?.toString() ?? '0') : '0',
    );

    if (inv != null) {
      invoiceType = inv['type'] ?? 'مبيعات';
      paymentType = inv['paymentType'] ?? 'نقدي';
      previousBalance = (inv['previousBalance'] as num?)?.toDouble() ?? 0.0;
      if (inv['items'] != null) {
        invoiceItems = List<Map<String, dynamic>>.from(
          (inv['items'] as List).map((item) => Map<String, dynamic>.from(item)),
        );
      }
    }
  }

  // دالة لجلب رصيد الزبون السابق تلقائياً عند تغيير اسم الزبون
  void _fetchCustomerPreviousBalance(String customerName) {
    setState(() {
      previousBalance = customerBalancesFromDB[customerName.trim()] ?? 0.0;
    });
  }

  @override
  void dispose() {
    customerController.dispose();
    exchangeRateController.dispose();
    globalDiscountController.dispose();
    paidAmountController.dispose();
    super.dispose();
  }

  double get subTotal {
    return invoiceItems.fold(0.0, (sum, item) {
      double itemPrice = (item['price'] as double) * (item['quantity'] as int);
      double itemDiscount = (item['discount'] as double? ?? 0.0);
      return sum + (itemPrice - itemDiscount);
    });
  }

  double get grandTotal {
    double discount = double.tryParse(globalDiscountController.text) ?? 0.0;
    return (subTotal - discount) < 0 ? 0.0 : (subTotal - discount);
  }

  // حساب الرصيد الحالي: (الرصيد السابق المسجل + صافي الفاتورة) - الدفعة المقدمة
  double get currentBalance {
    double paid = double.tryParse(paidAmountController.text) ?? 0.0;
    return (previousBalance + grandTotal) - paid;
  }

  void _showAddProductDialog() {
    if (!isEditing) return;

    String selectedProductName = availableProducts[0]['name'];
    double selectedPrice = availableProducts[0]['price'];

    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController priceController = TextEditingController(text: selectedPrice.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('إضافة منتج للفاتورة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedProductName,
                      decoration: const InputDecoration(labelText: 'اختر المنتج', border: OutlineInputBorder()),
                      items: availableProducts.map((prod) {
                        return DropdownMenuItem<String>(
                          value: prod['name'],
                          child: Text(prod['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final prod = availableProducts.firstWhere((p) => p['name'] == val);
                          setDialogState(() {
                            selectedProductName = val;
                            selectedPrice = prod['price'];
                            priceController.text = selectedPrice.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'السعر (ل.س)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0277BD)),
                  onPressed: () {
                    int qty = int.tryParse(quantityController.text) ?? 1;
                    double price = double.tryParse(priceController.text) ?? 0.0;

                    if (qty > 0 && price >= 0) {
                      setState(() {
                        invoiceItems.add({
                          'name': selectedProductName,
                          'price': price,
                          'quantity': qty,
                          'discount': 0.0,
                        });
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('إضافة', style: TextStyle(color: Colors.white)),
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
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
        title: Text(
          isNewInvoice ? 'فاتورة جديدة' : (widget.existingInvoice?['id'] ?? 'تفاصيل الفاتورة'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (!isNewInvoice && !isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'تعديل الفاتورة',
              onPressed: () {
                setState(() {
                  isEditing = true;
                  backupItems = List<Map<String, dynamic>>.from(
                    invoiceItems.map((e) => Map<String, dynamic>.from(e)),
                  );
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (!isNewInvoice && isEditing)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('أنت الآن في وضع التعديل على الفاتورة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نوع الفاتورة:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'مبيعات', label: Text('مبيعات')),
                            ButtonSegment(value: 'مشتريات', label: Text('مشتريات')),
                          ],
                          selected: {invoiceType},
                          onSelectionChanged: isEditing
                              ? (val) => setState(() => invoiceType = val.first)
                              : null,
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'نقدي', label: Text('نقدي')),
                            ButtonSegment(value: 'آجل (دين)', label: Text('آجل (دين)')),
                          ],
                          selected: {paymentType},
                          onSelectionChanged: isEditing
                              ? (val) => setState(() => paymentType = val.first)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customerController,
                      enabled: isEditing,
                      textAlign: TextAlign.right,
                      onChanged: _fetchCustomerPreviousBalance,
                      decoration: InputDecoration(
                        labelText: 'اسم العميل',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0277BD)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isEditing)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    side: const BorderSide(color: Color(0xFF0277BD)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF0277BD)),
                  label: const Text('إضافة منتج للفاتورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                  onPressed: _showAddProductDialog,
                ),
              ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invoiceItems.length,
              itemBuilder: (context, index) {
                final item = invoiceItems[index];
                final double totalItemPrice = (item['price'] as double) * (item['quantity'] as int) - (item['discount'] as double? ?? 0.0);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    invoiceItems.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الكمية: ${item['quantity']} × ${item['price']} ل.س', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('$totalItemPrice ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 30),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الفرعي:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${subTotal.toStringAsFixed(1)} ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي الفاتورة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${grandTotal.toStringAsFixed(1)} ل.س', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ================== بطاقة التسوية المالية ==================
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // 1. رصيد سابق (عرض قراءة فقط يجلب تلقائياً من داتابيز العميل)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: Color(0xFF0277BD)),
                            SizedBox(width: 8),
                            Text('رصيد سابق مترتب:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text(
                          '${previousBalance.toStringAsFixed(1)} ل.س',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: previousBalance > 0 ? Colors.red : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // 2. الدفعة المدفوعة حالياً (حقل إدخال)
                    TextField(
                      controller: paidAmountController,
                      enabled: isEditing,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'الدفعة المقبوضة',
                        prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Divider(height: 20),

                    // 3. الرصيد الحالي المحسوب تلقائياً
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الرصيد الحالي المتبقي:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${currentBalance.toStringAsFixed(1)} ل.س',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentBalance > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // زر الحفظ
            if (isEditing)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0277BD),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ الفاتورة وتحديث حساب الزبون بنجاح')),
                        );
                        if (isNewInvoice) Navigator.pop(context);
                      },
                      child: Text(isNewInvoice ? 'حفظ الفاتورة' : 'حفظ التعديلات', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  if (!isNewInvoice) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                            invoiceItems = List<Map<String, dynamic>>.from(
                              backupItems.map((e) => Map<String, dynamic>.from(e)),
                            );
                          });
                        },
                        child: const Text('إلغاء التعديل', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ]
                ],
              )
          ],
        ),
      ),
    );
  }
}
