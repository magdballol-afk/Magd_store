import 'package:flutter/material.dart';

class ContactDetailsScreen extends StatelessWidget {
  final dynamic contact;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    // استخراج البيانات سواء كان الكائن Map أو Model
    final String name = contact is Map ? (contact['name'] ?? '') : (contact.name ?? '');
    final String phone = contact is Map ? (contact['phone'] ?? 'غير محدد') : (contact.phone ?? 'غير محدد');
    final double balance = contact is Map 
        ? ((contact['balance'] as num?)?.toDouble() ?? 0.0) 
        : ((contact.balance as num?)?.toDouble() ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'تفاصيل جهة الاتصال'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF0284C7)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('الهاتف: $phone'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                title: const Text('الرصيد / الدين'),
                subtitle: Text('$balance ل.س'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
