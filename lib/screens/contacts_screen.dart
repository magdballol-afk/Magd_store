import 'package:flutter/material.dart';
import '../database/database_helper.dart';

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
    try {
      final db = await DatabaseHelper.instance.database;
      final rawData = await db.query('parties', orderBy: 'name ASC');
      setState(() {
        _contacts = rawData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'عميل';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة جهة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الجهة / الشخص'),
                ),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'عميل', child: Text('عميل')),
                    DropdownMenuItem(value: 'مورد', child: Text('مورد')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedType = val;
                  },
                  decoration: const InputDecoration(labelText: 'نوع الجهة'),
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
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final db = await DatabaseHelper.instance.database;
                await db.insert('parties', {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'type': selectedType,
                  'balance_syp': 0.0,
                  'balance_usd': 0.0,
                });
                if (mounted) Navigator.pop(context);
                _loadContacts();
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل العملاء والموردين'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('لا يوجد عملاء أو موردين حالياً'))
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final item = _contacts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(item['name']?[0] ?? 'C'),
                        ),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text('الهاتف: ${item['phone'] ?? "غير محدد"} | النوع: ${item['type'] ?? "عميل"}'),
                        trailing: Text(
                          '${item['balance_syp'] ?? 0} ل.س',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
