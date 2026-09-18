import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'contact_detail_screen.dart'; // استيراد الملف بالشكل الصحيح

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
                          // التوجيه الصحيح إلى ContactDetailScreen بدون S الزائدة
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailScreen(contact: item),
                            ),
                          );
                          _loadContacts(); // إعادة التحميل عند العودة لتحديث الرصيد
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
. 
