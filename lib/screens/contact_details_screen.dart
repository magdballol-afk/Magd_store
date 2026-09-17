import 'package:flutter/material.dart';

class ContactDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
  });

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact['name'] ?? 'تفاصيل جهة الاتصال'),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF0284C7)),
                title: Text(widget.contact['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('الهاتف: ${widget.contact['phone'] ?? 'غير محدد'}'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                title: const Text('الرصيد / الدين'),
                subtitle: Text('${widget.contact['balance'] ?? 0.0} ل.س'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
