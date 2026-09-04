import 'package:flutter/material.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  // 1. سعر الصرف (يمكنك تعديله)
  double _exchangeRate = 15000.0; 
  
  // 2. العملة المحددة حالياً (SYP أو USD)
  String _selectedCurrency = 'SYP';

  // 3. قائمة منتجات الفاتورة الحالية
  final List<Map<String, dynamic>> _invoiceItems = [];
  
  // متحكمات الحقول عند إضافة منتج
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  // حساب الإجمالي بالليرة السورية
  double get _totalInSyp {
    double total = 0.0;
    for (var item in _invoiceItems) {
      if (item['currency'] == 'USD') {
        total += (item['total'] as double) * _exchangeRate;
      } else {
        total += item['total'] as double;
      }
    }
    return total;
  }

  // حساب الإجمالي بالدولار
  double get _totalInUsd {
    return _exchangeRate > 0 ? _totalInSyp / _exchangeRate : 0.0;
  }

  // دالة إضافة عنصر إلى الفاتورة
  void _addItem() {
    final String name = _nameController.text.trim();
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final int quantity = int.tryParse(_quantityController.text) ?? 1;

    if (name.isNotEmpty && price > 0) {
      setState(() {
        _invoiceItems.add({
          'name': name,
          'quantity': quantity,
          'price': price,
          'currency': _selectedCurrency,
          'total': price * quantity,
        });
      });
      _nameController.clear();
      _priceController.clear();
      _quantityController.text = '1';
      Navigator.pop(context); // إغلاق نافذة الإدخال
    }
  }

  // نافذة إدخال تفاصيل المنتج
  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('إضافة منتج للفاتورة', textAlign: TextAlign.right),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'اسم المنتج'),
                    textAlign: TextAlign.right,
                  ),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'السعر (${_selectedCurrency == 'SYP' ? 'ل.س' : '\$'})',
                    ),
                    textAlign: TextAlign.right,
                  ),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الكمية'),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
                  // اختيار العملة للمنتج
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('ليرة سورية (SYP)'),
                        selected: _selectedCurrency == 'SYP',
                        onSelected: (selected) {
                          if (selected) setDialogState(() => _selectedCurrency = 'SYP');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('دولار (USD)'),
                        selected: _selectedCurrency == 'USD',
                        onSelected: (selected) {
                          if (selected) setDialogState(() => _selectedCurrency = 'USD');
                        },
                      ),
                    ],
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
                onPressed: _addItem,
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('فاتورة جديدة'),
          backgroundColor: const Color(0xFF0D47A1),
          actions: [
            IconButton(
              icon: const Icon(Icons.currency_exchange),
              tooltip: 'تغيير سعر الصرف',
              onPressed: _showExchangeRateDialog,
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // عرض سعر الصرف
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('سعر الصرف:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('1 \$ = ${_exchangeRate.toStringAsFixed(0)} ل.س',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('إضافة منتج للفاتورة'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              // عرض قائمة المنتجات المضافة
              Expanded(
                child: _invoiceItems.isEmpty
                    ? const Center(child: Text('لم يتم إضافة أي منتجات بعد'))
                    : ListView.builder(
                        itemCount: _invoiceItems.length,
                        itemBuilder: (context, index) {
                          final item = _invoiceItems[index];
                          final currencySymbol = item['currency'] == 'USD' ? '\$' : 'ل.س';
                          return Card(
                            child: ListTile(
                              title: Text(item['name']),
                              subtitle: Text('الكمية: ${item['quantity']} × ${item['price']} $currencySymbol'),
                              trailing: Text(
                                '${item['total']} $currencySymbol',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              // بطاقة الإجمالي بالعملتين
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي (SYP):', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${_totalInSyp.toStringAsFixed(0)} ل.س',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي (USD):', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${_totalInUsd.toStringAsFixed(2)} \$',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _invoiceItems.isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('حفظ وإصدار الفاتورة', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // نافذة تعديل سعر الصرف
  void _showExchangeRateDialog() {
    final TextEditingController rateController = TextEditingController(text: _exchangeRate.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل سعر الصرف', textAlign: TextAlign.right),
        content: TextField(
          controller: rateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'سعر 1 دولار بالليرة السورية'),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(rateController.text);
              if (newRate != null && newRate > 0) {
                setState(() => _exchangeRate = newRate);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
