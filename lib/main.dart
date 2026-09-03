    import 'package:flutter/material.dart';

void main() {
  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحاسب الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainAppScreen(),
      ),
    );
  }
}

enum InvoiceType { sale, purchase }
enum PaymentType { cash, deferred }

class Product {
  final String id;
  final String name;
  double price;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class Invoice {
  final String id;
  final InvoiceType invoiceType;
  final PaymentType paymentType;
  final String partyName;
  final List<Product> items;
  final double totalAmount;
  final DateTime date;

  Invoice({
    required this.id,
    required this.invoiceType,
    required this.paymentType,
    required this.partyName,
    required this.items,
    required this.totalAmount,
    required this.date,
  });
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  final List<Product> _products = [
    Product(id: '1', name: 'منتج أفتراضي A', price: 25.0, quantity: 50),
    Product(id: '2', name: 'منتج أفتراضي B', price: 100.0, quantity: 20),
  ];

  final List<Invoice> _invoices = [];

  double get totalSales => _invoices
      .where((inv) => inv.invoiceType == InvoiceType.sale)
      .fold(0, (sum, inv) => sum + inv.totalAmount);

  double get totalPurchases => _invoices
      .where((inv) => inv.invoiceType == InvoiceType.purchase)
      .fold(0, (sum, inv) => sum + inv.totalAmount);

  void _addInvoice(Invoice invoice) {
    setState(() {
      for (var item in invoice.items) {
        var index = _products.indexWhere((p) => p.name == item.name);
        if (index != -1) {
          if (invoice.invoiceType == InvoiceType.sale) {
            _products[index].quantity -= item.quantity;
          } else {
            _products[index].quantity += item.quantity;
          }
        } else {
          if (invoice.invoiceType == InvoiceType.purchase) {
            _products.add(item);
          }
        }
      }
      _invoices.insert(0, invoice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحل التجاري'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'المبيعات',
                    '${totalSales.toStringAsFixed(1)} ر.س',
                    Colors.green.shade100,
                    Colors.green.shade900,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'المشتريات',
                    '${totalPurchases.toStringAsFixed(1)} ر.س',
                    Colors.orange.shade100,
                    Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateInvoiceScreen(),
                  ),
                );
                if (result != null && result is Invoice) {
                  _addInvoice(result);
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('إنشاء فاتورة جديدة', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'سجل الفواتير الأخيرة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _invoices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('لا توجد فواتير مسجلة حتى الآن')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final inv = _invoices[index];
                      final isSale = inv.invoiceType == InvoiceType.sale;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSale ? Colors.green : Colors.orange,
                            child: Icon(
                              isSale ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.white,
                            ),
                          ),
                          title: Text('${isSale ? "بيع" : "شراء"} - ${inv.partyName}'),
                          subtitle: Text(
                              'الدفع: ${inv.paymentType == PaymentType.cash ? "نقدي" : "آجل"}'),
                          trailing: Text(
                            '${inv.totalAmount.toStringAsFixed(1)} ر.س',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textCol, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  InvoiceType _invoiceType = InvoiceType.sale;
  PaymentType _paymentType = PaymentType.cash;

  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  final List<Product> _selectedProducts = [];

  void _addProduct() {
    final name = _productNameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_qtyController.text) ?? 1;

    if (name.isNotEmpty && price > 0) {
      setState(() {
        _selectedProducts.add(Product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          price: price,
          quantity: qty,
        ));
        _productNameController.clear();
        _priceController.clear();
        _qtyController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إنشاء فاتورة جديدة')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('فاتورة بيع')),
                      selected: _invoiceType == InvoiceType.sale,
                      onSelected: (_) => setState(() => _invoiceType = InvoiceType.sale),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('فاتورة شراء')),
                      selected: _invoiceType == InvoiceType.purchase,
                      onSelected: (_) => setState(() => _invoiceType = InvoiceType.purchase),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('نقدي (كاش)'),
                    selected: _paymentType == PaymentType.cash,
                    onSelected: (_) => setState(() => _paymentType = PaymentType.cash),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('آجل (ذمم)'),
                    selected: _paymentType == PaymentType.deferred,
                    onSelected: (_) => setState(() => _paymentType = PaymentType.deferred),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _partyNameController,
                decoration: InputDecoration(
                  labelText: _invoiceType == InvoiceType.sale ? 'اسم العميل' : 'اسم المورد',
                  border: const OutlineInputBorder(),
                ),
              ),
              const Divider(height: 32),

              const Text('إضافة صنف للفاتورة', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('أضف الصنف للفاتورة'),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedProducts.length,
                itemBuilder: (context, index) {
                  final item = _selectedProducts[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('الكمية: ${item.quantity} × ${item.price} ر.س'),
                    trailing: Text('${item.quantity * item.price} ر.س'),
                  );
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_partyNameController.text.isNotEmpty && _selectedProducts.isNotEmpty) {
                    double total = _selectedProducts.fold(
                        0, (sum, item) => sum + (item.price * item.quantity));
                    
                    final newInvoice = Invoice(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      invoiceType: _invoiceType,
                      paymentType: _paymentType,
                      partyName: _partyNameController.text,
                      items: List.from(_selectedProducts),
                      totalAmount: total,
                      date: DateTime.now(),
                    );

                    Navigator.pop(context, newInvoice);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حفظ واصدار الفاتورة'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
      

  

