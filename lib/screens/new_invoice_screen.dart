import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../database/database_helper.dart';
import '../services/print_service.dart';

class NewInvoiceScreen extends StatefulWidget {
  final String? type;
  final int? invoiceId;

  const NewInvoiceScreen({Key? key, this.type, this.invoiceId}) : super(key: key);

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  late String _invoiceType; // 'sale' أو 'purchase'

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _products = [];

  int? _selectedContactId;
  String _selectedContactName = 'عام / غير محدد';

  final List<Map<String, dynamic>> _invoiceItems = [];

  final TextEditingController _invoiceDiscountController = TextEditingController(text: '0');
  final TextEditingController _paidAmountController = TextEditingController(text: '0');

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _invoiceType = widget.type ?? 'sale';
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final contactsData = await DatabaseHelper.instance.getContacts();
      final productsData = await DatabaseHelper.instance.getProducts();

      setState(() {
        _contacts = contactsData;
        _products = productsData;
      });

      if (widget.invoiceId != null) {
        await _loadInvoiceDetails(widget.invoiceId!);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadInvoiceDetails(int invoiceId) async {
    final db = await DatabaseHelper.instance.database;

    final invoiceResult = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );

    if (invoiceResult.isNotEmpty) {
      final invoice = invoiceResult.first;

      _invoiceType = (invoice['type'] ?? 'sale').toString();
      _selectedContactId = invoice['contact_id'] != null
          ? (invoice['contact_id'] as num).toInt()
          : null;

      _invoiceDiscountController.text = (invoice['discount'] ?? 0.0).toString();
      _paidAmountController.text = (invoice['paid_amount'] ?? 0.0).toString();

      if (_selectedContactId != null) {
        final contactMatch = _contacts.firstWhere(
          (c) => c['id'] == _selectedContactId,
          orElse: () => {},
        );
        if (contactMatch.isNotEmpty) {
          _selectedContactName = contactMatch['name']?.toString() ?? 'عام / غير محدد';
        } else {
          _selectedContactName = invoice['contact_name']?.toString() ?? 'عام / غير محدد';
        }
      } else {
        _selectedContactName = invoice['contact_name']?.toString() ?? 'عام / غير محدد';
      }

      final itemsResult = await db.rawQuery('''
        SELECT ii.*, p.name AS product_name
        FROM invoice_items ii
        LEFT JOIN products p ON ii.product_id = p.id
        WHERE ii.invoice_id = ?
      ''', [invoiceId]);

      _invoiceItems.clear();
      for (var item in itemsResult) {
        final unitPrice = double.tryParse((item['price'] ?? item['unit_price'] ?? 0.0).toString()) ?? 0.0;
        final quantity = double.tryParse((item['quantity'] ?? 0.0).toString()) ?? 0.0;
        final discount = double.tryParse((item['discount'] ?? 0.0).toString()) ?? 0.0;
        final total = double.tryParse((item['total'] ?? 0.0).toString()) ?? 0.0;

        _invoiceItems.add({
          'product_id': item['product_id'],
          'product_name': item['product_name'] ?? item['item_name'] ?? 'مادة',
          'unit_price': unitPrice,
          'quantity': quantity,
          'discount': discount,
          'total': total,
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  double get _subtotal {
    return _invoiceItems.fold(0.0, (sum, item) {
      final total = double.tryParse((item['total'] ?? 0.0).toString()) ?? 0.0;
      return sum + total;
    });
  }

  double get _overallDiscount {
    return double.tryParse(_invoiceDiscountController.text.trim()) ?? 0.0;
  }

  double get _finalTotal {
    final double total = _subtotal - _overallDiscount;
    return total < 0 ? 0.0 : total;
  }

  double get _paidAmount {
    return double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
  }

  double get _remainingAmount {
    final double remaining = _finalTotal - _paidAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  void _addProductByBarcode(String barcodeCode) {
    final String cleanBarcode = barcodeCode.trim();
    if (cleanBarcode.isEmpty) return;

    final productMatch = _products.firstWhere(
      (p) => (p['barcode'] ?? '').toString().trim() == cleanBarcode,
      orElse: () => {},
    );

    if (productMatch.isNotEmpty) {
      final double defaultPrice = _invoiceType == 'purchase'
          ? (productMatch['buy_price'] as num?)?.toDouble() ?? 0.0
          : (productMatch['retail_price'] as num?)?.toDouble() ?? 0.0;

      final int existingIndex = _invoiceItems.indexWhere((item) => item['product_id'] == productMatch['id']);

      setState(() {
        if (existingIndex >= 0) {
          final currentQty = (_invoiceItems[existingIndex]['quantity'] as num).toDouble();
          final newQty = currentQty + 1.0;
          final disc = (_invoiceItems[existingIndex]['discount'] as num).toDouble();
          final unitPrice = (_invoiceItems[existingIndex]['unit_price'] as num).toDouble();
          final total = (unitPrice * newQty) - disc;

          _invoiceItems[existingIndex]['quantity'] = newQty;
          _invoiceItems[existingIndex]['total'] = total < 0 ? 0.0 : total;
        } else {
          _invoiceItems.add({
            'product_id': productMatch['id'],
            'product_name': productMatch['name'] ?? 'مادة',
            'unit_price': defaultPrice,
            'quantity': 1.0,
            'discount': 0.0,
            'total': defaultPrice,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة: ${productMatch['name']}'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لم يتم العثور على مادة بباركود: $cleanBarcode'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _scanBarcodeAndAdd() async {
    final String? scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerSimpleScreen(),
      ),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      _addProductByBarcode(scannedBarcode);
    }
  }

  Future<void> _printInvoice() async {
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن طباعة فاتورة فارغة')),
      );
      return;
    }

    double currentContactBalance = 0.0;
    final int? contactId = _selectedContactId;
    if (contactId != null && contactId > 0) {
      final contacts = await DatabaseHelper.instance.getContacts();
      final contactMatch = contacts.firstWhere(
        (c) => c['id'] == contactId,
        orElse: () => {},
      );
      if (contactMatch.isNotEmpty) {
        currentContactBalance = (contactMatch['balance'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final formattedItems = _invoiceItems.map((item) {
      return {
        'name': item['product_name'] ?? 'مادة',
        'quantity': item['quantity'] ?? 1,
        'price': item['unit_price'] ?? 0.0,
      };
    }).toList();

    final String invoiceNumberStr = widget.invoiceId != null
        ? "${widget.invoiceId}"
        : "DRAFT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

    final String displayType = _invoiceType == 'purchase' ? 'فاتورة مشتريات' : 'فاتورة مبيعات';

    await PrintService.selectAndPrintInvoice(
      context: context,
      invoiceType: displayType,
      invoiceNumber: invoiceNumberStr,
      customerName: _selectedContactName,
      items: formattedItems,
      totalPrice: _finalTotal,
      paidAmount: _paidAmount,
      remainingAmount: _remainingAmount,
      customerBalance: currentContactBalance,
      currency: "",
    );
  }

  void _showContactSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredList = _contacts.where((c) {
              final name = (c['name'] ?? '').toString().toLowerCase();
              final phone = (c['phone'] ?? '').toString();
              return name.contains(filter.toLowerCase()) || phone.contains(filter);
            }).toList();

            return AlertDialog(
              title: const Text('بحث واختيار عميل'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'ابحث بالاسم أو الهاتف...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() => filter = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.person_off, color: Colors.grey),
                      title: const Text('عميل عام / غير محدد'),
                      onTap: () {
                        setState(() {
                          _selectedContactId = null;
                          _selectedContactName = 'عام / غير محدد';
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    SizedBox(
                      height: 250,
                      child: filteredList.isEmpty
                          ? const Center(child: Text('لا توجد نتائج'))
                          : ListView.builder(
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final contact = filteredList[index];
                                return ListTile(
                                  title: Text(contact['name'] ?? ''),
                                  subtitle: Text(contact['phone'] ?? 'بدون رقم'),
                                  onTap: () {
                                    setState(() {
                                      _selectedContactId = contact['id'];
                                      _selectedContactName = contact['name'];
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemDialog() {
    Map<String, dynamic>? selectedProduct;
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final discountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (dialogContext) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredProducts = _products.where((p) {
              final name = (p['name'] ?? '').toString().toLowerCase();
              final barcode = (p['barcode'] ?? '').toString().toLowerCase();
              return name.contains(filter.toLowerCase()) || barcode.contains(filter.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('إضافة مادة للفاتورة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedProduct == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'ابحث باسم المادة أو الباركود...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) => setDialogState(() => filter = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF5C6BC0), size: 30),
                            tooltip: 'مسح باركود',
                            onPressed: () async {
                              final barcode = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BarcodeScannerSimpleScreen(),
                                ),
                              );
                              if (barcode != null && barcode.isNotEmpty) {
                                final found = _products.firstWhere(
                                  (p) => (p['barcode'] ?? '').toString().trim() == barcode.trim(),
                                  orElse: () => {},
                                );
                                if (found.isNotEmpty) {
                                  setDialogState(() {
                                    selectedProduct = found;
                                    final double defaultPrice = _invoiceType == 'purchase'
                                        ? (found['buy_price'] as num?)?.toDouble() ?? 0.0
                                        : (found['retail_price'] as num?)?.toDouble() ?? 0.0;

                                    priceController.text = defaultPrice > 0 ? defaultPrice.toString() : '';
                                  });
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('لم يتم العثور على مادة بباركود: $barcode')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final prod = filteredProducts[index];
                            final double productRetailPrice = (prod['retail_price'] as num?)?.toDouble() ?? 
                                                              (prod['buy_price'] as num?)?.toDouble() ?? 0.0;

                            return ListTile(
                              title: Text(prod['name'] ?? ''),
                              subtitle: Text('المتوفر: ${prod['quantity']} | السعر: $productRetailPrice | باركود: ${prod['barcode'] ?? 'لا يوجد'}'),
                              onTap: () {
                                setDialogState(() {
                                  selectedProduct = prod;
                                  final double defaultPrice = _invoiceType == 'purchase' 
                                      ? (prod['buy_price'] as num?)?.toDouble() ?? 0.0
                                      : (prod['retail_price'] as num?)?.toDouble() ?? 0.0;
                                      
                                  priceController.text = defaultPrice > 0 ? defaultPrice.toString() : '';
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Card(
                        color: Colors.indigo.shade50,
                        child: ListTile(
                          title: Text(selectedProduct!['name'] ?? ''),
                          subtitle: Text('المخزون الحالي: ${selectedProduct!['quantity']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setDialogState(() => selectedProduct = null),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'السعر (يقبل الفواصل)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'الكمية (مثل 1 أو 1.5)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: discountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'حسم على المادة (اختياري)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_offer),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                if (selectedProduct != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0)),
                    onPressed: () {
                      final double price = double.tryParse(priceController.text.trim()) ?? 0.0;
                      final double qty = double.tryParse(quantityController.text.trim()) ?? 0.0;
                      final double disc = double.tryParse(discountController.text.trim()) ?? 0.0;

                      if (qty <= 0) return;

                      final double total = (price * qty) - disc;

                      setState(() {
                        _invoiceItems.add({
                          'product_id': selectedProduct!['id'],
                          'product_name': selectedProduct!['name'] ?? 'مادة',
                          'unit_price': price,
                          'quantity': qty,
                          'discount': disc,
                          'total': total < 0 ? 0.0 : total,
                        });
                      });

                      Navigator.pop(dialogContext);
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

  Future<void> _saveInvoice() async {
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة مادة واحدة على الأقل')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> dbItems = _invoiceItems.map((item) => {
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'price': item['unit_price'],
        'total': item['total'],
      }).toList();

      if (widget.invoiceId != null) {
        await DatabaseHelper.instance.updateFullInvoice(
          invoiceId: widget.invoiceId!,
          contactId: _selectedContactId,
          type: _invoiceType,
          totalAmount: _subtotal,
          discount: _overallDiscount,
          netAmount: _finalTotal,
          paidAmount: _paidAmount,
          itemsList: dbItems,
        );
      } else {
        await DatabaseHelper.instance.addFullInvoice(
          contactId: _selectedContactId ?? 0,
          type: _invoiceType,
          totalAmount: _subtotal,
          discount: _overallDiscount,
          netAmount: _finalTotal,
          paidAmount: _paidAmount,
          itemsList: dbItems,
          date: DateTime.now().toString().split(' ')[0],
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.invoiceId != null
                  ? 'تم تحديث الفاتورة وتعديل الأرصدة والصندوق بنجاح'
                  : 'تم حفظ الفاتورة وتحديث الحسابات والصندوق بنجاح',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تنفيذ العملية: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.invoiceId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'تعديل فاتورة #${widget.invoiceId}'
              : (_invoiceType == 'purchase' ? 'فاتورة شراء جديدة' : 'فاتورة مبيعات جديدة'),
        ),
        backgroundColor: const Color(0xFF5C6BC0),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'مسح باركود إضافة مباشرة',
            onPressed: _scanBarcodeAndAdd,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'طباعة الفاتورة',
            onPressed: _printInvoice,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'sale', label: Text('فاتورة مبيعات'), icon: Icon(Icons.sell)),
                      ButtonSegment(value: 'purchase', label: Text('فاتورة مشتريات'), icon: Icon(Icons.shopping_cart)),
                    ],
                    selected: {_invoiceType},
                    onSelectionChanged: (val) {
                      setState(() => _invoiceType = val.first);
                    },
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _showContactSearchDialog,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'الحساب / العميل (اضغط للبحث المتقدم)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      child: Text(
                        _selectedContactName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المواد المضافة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF5C6BC0)),
                            tooltip: 'مسح باركود',
                            onPressed: _scanBarcodeAndAdd,
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('إضافة مادة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C6BC0),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Expanded(
                    child: _invoiceItems.isEmpty
                        ? const Center(child: Text('لم يتم إضافة مواد بعد'))
                        : ListView.builder(
                            itemCount: _invoiceItems.length,
                            itemBuilder: (context, index) {
                              final item = _invoiceItems[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(item['product_name'] ?? 'مادة'),
                                  subtitle: Text(
                                    'الكمية: ${item['quantity']} × السعر: ${item['unit_price']} ${item['discount'] > 0 ? '| حسم: ${item['discount']}' : ''}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        (item['total'] as double).toStringAsFixed(2),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() => _invoiceItems.removeAt(index));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const Divider(thickness: 2),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceDiscountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'حسم كلي على الفاتورة',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _paidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'الدفعة المسددة نقدياً',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المجموع: ${_subtotal.toStringAsFixed(2)}'),
                            Text(
                              'قيمة الفاتورة (الصافي): ${_finalTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF5C6BC0)),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المدفوع نقدياً: ${_paidAmount.toStringAsFixed(2)}'),
                            Text(
                              'المتبقي (على الحساب): ${_remainingAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _remainingAmount > 0 ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C6BC0)),
                      onPressed: _isSaving ? null : _saveInvoice,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing ? 'تحديث الفاتورة' : 'حفظ الفاتورة',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class BarcodeScannerSimpleScreen extends StatefulWidget {
  const BarcodeScannerSimpleScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerSimpleScreen> createState() => _BarcodeScannerSimpleScreenState();
}

class _BarcodeScannerSimpleScreenState extends State<BarcodeScannerSimpleScreen> {
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسح الباركود'),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_hasScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              setState(() => _hasScanned = true);
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}
