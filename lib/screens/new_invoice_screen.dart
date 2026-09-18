import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class NewInvoiceScreen extends StatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  List<Map<String, dynamic>> _contacts = [];
  Map<String, dynamic>? _selectedContact;
  final TextEditingController _contactSearchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final db = await DatabaseHelper.instance.database;
    final contactsData = await db.query('contacts', orderBy: 'name ASC');
    setState(() {
      _contacts = contactsData;
      _isLoading = false;
    });
  }

  // نافذة إضافة عميل/مورد جديد
  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة جهة اتصال جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                final id = await db.insert('contacts', {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'balance_syr': 0.0,
                });
                if (mounted) Navigator.pop(context);
                await _loadContacts();
                
                // تحديد العميل المضاف حديثاً وتحديث التكست بوكس
                final newContact = _contacts.firstWhere((e) => e['id'] == id);
                setState(() {
                  _selectedContact = newContact;
                  _contactSearchController.text = newContact['name'] ?? '';
                });
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // حقل البحث المتقدم عن العميل / المورد
                      Expanded(
                        child: RawAutocomplete<Map<String, dynamic>>(
                          textEditingController: _contactSearchController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return _contacts;
                            }
                            return _contacts.where((Map<String, dynamic> option) {
                              final name = option['name'].toString().toLowerCase();
                              final phone = option['phone']?.toString().toLowerCase() ?? '';
                              final input = textEditingValue.text.toLowerCase();
                              return name.contains(input) || phone.contains(input);
                            });
                          },
                          displayStringForOption: (Map<String, dynamic> option) =>
                              option['name'] ?? '',
                          onSelected: (Map<String, dynamic> selection) {
                            setState(() {
                              _selectedContact = selection;
                            });
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'اسم العميل / المورد (ابحث هنا)',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          controller.clear();
                                          setState(() => _selectedContact = null);
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  constraints: const BoxConstraints(maxHeight: 250),
                                  width: MediaQuery.of(context).size.width - 90,
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (BuildContext context, int index) {
                                      final Map<String, dynamic> option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option['name'] ?? ''),
                                        subtitle: Text(option['phone'] ?? 'بدون رقم هاتف'),
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
                      ),
                      const SizedBox(width: 8),
                      // زر إضافة عميل جديد
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.person_add),
                        onPressed: _showAddContactDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
