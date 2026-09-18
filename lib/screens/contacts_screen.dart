import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('contacts', orderBy: 'name ASC');
    setState(() {
      _contacts = data;
      _isLoading = false;
    });
  }

  // نافذة إضافة عميل جديد من زر +
  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة حساب جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'الرصيد الأولي (ل.س)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final db = await DatabaseHelper.instance.database;
                await db.insert('contacts', {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'balance_syr': double.tryParse(balanceController.text) ?? 0.0,
                });
                if (mounted) Navigator.pop(context);
                _loadContacts();
              }
            },
            child: const Text('حفظ الحساب'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جهات الاتصال / الحسابات'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('لا يوجد حسابات مسجلة حالياً'))
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final item = _contacts[index];
                    final double balance = ((item['balance_syr'] ?? item['balance'] ?? 0.0) as num).toDouble();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF0284C7),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text(item['phone'] ?? 'بدون رقم هاتف'),
                        trailing: Text(
                          '${balance.abs().toStringAsFixed(2)} ل.س',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: balance > 0
                                ? Colors.red
                                : balance < 0
                                    ? Colors.blue
                                    : Colors.green,
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailScreen(contact: item),
                            ),
                          );
                          _loadContacts();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0284C7),
        onPressed: _showAddContactDialog, // ربط زر + بفتح نافذة الإضافة
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
