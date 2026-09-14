import 'package:flutter/material.dart';
import '../database/database_helper.dart';

// ... (باقي الكود والكلاس الأساسي للـ State)

  // دالة إظهار نافذة إضافة منتج للفاتورة مع البحث المتقدم
  void _showAddProductDialog() async {
    // 1. جلب كافة المنتجات من قاعدة البيانات المحلية لاستخدامها في البحث
    final allProducts = await DatabaseHelper.instance.getAllProducts();

    Map<String, dynamic>? selectedProduct;
    final TextEditingController productSearchController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulWidget(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة منتج للفاتورة', textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // حقل البحث المتقدم مع الإكمال التلقائي
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) => option['name'] as String,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        // عدم إظهار اقتراحات حتى يكتب المستخدم حرفين على الأقل
                        if (textEditingValue.text.length < 2) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return allProducts.where((product) {
                          final name = (product['name'] as String).toLowerCase();
                          final barcode = (product['barcode'] as String?)?.toLowerCase() ?? '';
                          final query = textEditingValue.text.toLowerCase();
                          return name.contains(query) || barcode.contains(query);
                        });
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        selectedProduct = selection;
                        
                        // تحديد السعر الافتراضي بناءً على نوع التعامل (مفرق / نصف جملة / جملة)
                        double defaultPrice = (selection['price_retail'] as num?)?.toDouble() ?? 0.0;
                        if (_selectedDealType == 'نصف جملة') {
                          defaultPrice = (selection['price_half_wholesale'] as num?)?.toDouble() ?? defaultPrice;
                        } else if (_selectedDealType == 'جملة') {
                          defaultPrice = (selection['price_wholesale'] as num?)?.toDouble() ?? defaultPrice;
                        }

                        setDialogState(() {
                          priceController.text = defaultPrice.toString();
                        });
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'اسم المنتج أو الباركود',
                            hintText: 'اكتب حرفين للبحث...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topRight,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              height: 200,
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option['name']),
                                    subtitle: Text('الكمية المتاحة: ${option['quantity']} | السعر: ${option['price_retail']}'),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // حقل السعر (قابلة للتعديل)
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'السعر',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // حقل الكمية
                    TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
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
                  onPressed: () {
                    final String name = selectedProduct != null 
                        ? selectedProduct!['name'] 
                        : productSearchController.text;
                    final double? price = double.tryParse(priceController.text);
                    final double? qty = double.tryParse(quantityController.text);

                    if (name.isNotEmpty && price != null && qty != null && qty > 0) {
                      setState(() {
                        // إضافة المنتج إلى قائمة مواد الفاتورة
                        _invoiceItems.add({
                          'product_id': selectedProduct?['id'],
                          'product_name': name,
                          'price': price,
                          'quantity': qty,
                          'total': price * qty,
                        });
                        _calculateTotals(); // دالة اعادة حساب مجاميع الفاتورة
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }
