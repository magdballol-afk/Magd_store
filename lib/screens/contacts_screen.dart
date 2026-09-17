import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/contact_model.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactModel> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await DatabaseHelper.instance.getContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

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
                
                final newContact = ContactModel(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  balanceSyr: 0.0,
                  balanceUsd: 0.0,
                );

                await DatabaseHelper.instance.insertContact(newContact);
                
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
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailsScreen(contact: item),
                            ),
                          );
                          _loadContacts();
                        },
                        leading: CircleAvatar(
                          child: Text(item.name.isNotEmpty ? item.name[0] : 'C'),
                        ),
                        title: Text(item.name),
                        subtitle: Text('الهاتف: ${item.phone.isNotEmpty ? item.phone : "غير محدد"}'),
                        trailing: Text(
                          '${item.balanceSyr} ل.س',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
