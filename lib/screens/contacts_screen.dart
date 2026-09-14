import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../database/database_helper.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<ContactModel> _allContacts = [];
  List<ContactModel> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_filterContacts);
    _searchController.addListener(_filterContacts);
    _loadContactsFromDatabase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // جلب البيانات الحقيقية من قاعدة البيانات SQLite
  Future<void> _loadContactsFromDatabase() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> rawData = await DatabaseHelper.instance.getParties();
      
      setState(() {
        _allContacts = rawData.map((map) {
          return ContactModel(
            id: map['id'].toString(),
            name: map['name'] ?? '',
            phone: map['phone'] ?? '',
            address: map['address'] ?? '',
            type: map['type'] ?? 'عميل',
            balanceSYP: (map['balance_syp'] as num?)?.toDouble() ?? 0.0,
            balanceUSD: (map['balance_usd'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        _filterContacts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب البيانات: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // تصفية العملاء والموردين بناءً على حقل البحث والتبويب المحدد
  void _filterContacts() {
    final query = _searchController.text.trim().toLowerCase();
    final tabIndex = _tabController.index;

    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final matchesSearch = contact.name.toLowerCase().contains(query) ||
            contact.phone.contains(query);

        if (tabIndex == 0) { // الكل
          return matchesSearch;
        } else if (tabIndex == 1) { // عملاء فقط
          return matchesSearch && contact.type == 'عميل';
        } else { // موردين فقط
          return matchesSearch && contact.type == 'مورد';
        }
      }).toList();
    });
  }

  // نافذة إضافة عميل / مورد جديد مباشرة وحفظه في قاعدة البيانات
  void _showAddPartyDialog() {
    String partyType = 'عميل';
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final sypBalanceController = TextEditingController(text: '0');
    String sypDirection = 'مدين (عليه)';
    final usdBalanceController = TextEditingController(text: '0');
    String usdDirection = 'مدين (عليه)';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulWidget(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('إضافة $partyType جديد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('عميل'),
                          selected: partyType == 'عميل',
                          onSelected: (selected) {
                            if (selected) setDialogState(() => partyType = 'عميل');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('مورد'),
                          selected: partyType == 'مورد',
                          onSelected: (selected) {
                            if (selected) setDialogState(() => partyType = 'مورد');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'العنوان (اختياري)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('الرصيد الافتتاحي:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sypBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'الرصيد (ل.س)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('مدين (عليه)')),
                            selected: sypDirection == 'مدين (عليه)',
                            onSelected: (sel) => setDialogState(() => sypDirection = 'مدين (عليه)'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('دائن (له)')),
                            selected: sypDirection == 'دائن (له)',
                            onSelected: (sel) => setDialogState(() => sypDirection = 'دائن (له)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usdBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'الرصيد (\$)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('مدين (عليه)')),
                            selected: usdDirection == 'مدين (عليه)',
                            onSelected: (sel) => setDialogState(() => usdDirection = 'مدين (عليه)'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('دائن (له)')),
                            selected: usdDirection == 'دائن (له)',
                            onSelected: (sel) => setDialogState(() => usdDirection = 'دائن (له)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;

                            double sypVal = double.tryParse(sypBalanceController.text) ?? 0.0;
                            if (sypDirection == 'دائن (له)') sypVal = -sypVal;

                            double usdVal = double.tryParse(usdBalanceController.text) ?? 0.0;
                            if (usdDirection == 'دائن (له)') usdVal = -usdVal;

                            await DatabaseHelper.instance.insertParty({
                              'name': name,
                              'phone': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                              'type': partyType,
                              'balance_syp': sypVal,
                              'balance_usd': usdVal,
                            });

                            if (context.mounted) Navigator.pop(context);
                            _loadContactsFromDatabase();
                          },
                          child: const Text('حفظ'),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحسابات (العملاء والموردين)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'العملاء'),
            Tab(text: 'الموردين'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPartyDialog,
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث باسم أو رقم العميل/المورد...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? const Center(child: Text('لا توجد نتائج متطابقة'))
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: contact.type == 'عميل' ? Colors.blue.shade100 : Colors.orange.shade100,
                                child: Icon(
                                  contact.type == 'عميل' ? Icons.person : Icons.store,
                                  color: contact.type == 'عميل' ? Colors.blue : Colors.orange,
                                ),
                              ),
                              title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('هاتف: ${contact.phone.isEmpty ? 'لا يوجد' : contact.phone}'),
                              trailing: Column(
                                mainCenter: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${contact.balanceSYP} ل.س',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: contact.balanceSYP >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    '${contact.balanceUSD} \$',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: contact.balanceUSD >= 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContactDetailsScreen(contact: contact),
                                  ),
                                ).then((_) => _loadContactsFromDatabase());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
