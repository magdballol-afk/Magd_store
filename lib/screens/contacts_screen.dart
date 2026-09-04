import 'package:flutter/material.dart';
import '../models/contact_model.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  // قائمة مؤقتة محاكاة للبيانات (ستُربط بقاعدة البيانات لاحقاً)
  final List<ContactModel> _contactsList = [
    ContactModel(
      id: '1',
      name: 'أحمد محمود',
      phone: '0912345678',
      type: ContactType.client,
      balanceSyp: -250000, // عليه دَين
      balanceUsd: 0,
    ),
    ContactModel(
      id: '2',
      name: 'شركة البركة للتوريد',
      phone: '0987654321',
      type: ContactType.supplier,
      balanceSyp: 500000, // له مستحقات
      balanceUsd: 100,
    ),
  ];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // تصفية القائمة حسب النوع (عميل/مورد) ونص البحث
  List<ContactModel> _getFilteredContacts(ContactType type) {
    return _contactsList.where((contact) {
      final matchesType = contact.type == type;
      final matchesSearch = contact.name.contains(_searchQuery) || 
                            contact.phone.contains(_searchQuery);
      return matchesType && matchesSearch;
    }).toList();
  }

  // نافذة إضافة جهة اتصال جديدة
  void _showAddContactDialog(ContactType defaultType) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final balanceSypController = TextEditingController(text: '0');
    final balanceUsdController = TextEditingController(text: '0');
    ContactType selectedType = defaultType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              selectedType == ContactType.client ? 'إضافة عميل جديد' : 'إضافة مورد جديد',
              textAlign: TextAlign.right,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اختيار النوع
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('عميل'),
                        selected: selectedType == ContactType.client,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => selectedType = ContactType.client);
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('مورد'),
                        selected: selectedType == ContactType.supplier,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => selectedType = ContactType.supplier);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)),
                    textAlign: TextAlign.right,
                  ),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                    textAlign: TextAlign.right,
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'العنوان (اختياري)', prefixIcon: Icon(Icons.location_on)),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 10),
                  const Text('الرصيد الافتتاحي (إن وجد):', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: balanceSypController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الرصيد (ل.س)', prefixIcon: Icon(Icons.money)),
                    textAlign: TextAlign.right,
                  ),
                  TextField(
                    controller: balanceUsdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الرصيد (\$)', prefixIcon: Icon(Icons.attach_money)),
                    textAlign: TextAlign.right,
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
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    setState(() {
                      _contactsList.add(
                        ContactModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                          type: selectedType,
                          balanceSyp: double.tryParse(balanceSypController.text) ?? 0.0,
                          balanceUsd: double.tryParse(balanceUsdController.text) ?? 0.0,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('العملاء والموردون'),
          backgroundColor: const Color(0xFF0D47A1),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'العملاء'),
              Tab(icon: Icon(Icons.local_shipping), text: 'الموردون'),
            ],
          ),
        ),
        body: Column(
          children: [
            // شريط البحث
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم أو رقم هاتف...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
              ),
            ),
            
            // عرض القوائم حسب التبويب
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContactList(ContactType.client),
                  _buildContactList(ContactType.supplier),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            final currentType = _tabController.index == 0 
                ? ContactType.client 
                : ContactType.supplier;
            _showAddContactDialog(currentType);
          },
          backgroundColor: const Color(0xFF0D47A1),
          icon: const Icon(Icons.person_add),
          label: Text(_tabController.index == 0 ? 'إضافة عميل' : 'إضافة مورد'),
        ),
      ),
    );
  }

  // بناء قائمة الجهات
  Widget _buildContactList(ContactType type) {
    final filteredList = _getFilteredContacts(type);

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          type == ContactType.client ? 'لا يوجد عملاء مضافون بعد' : 'لا يوجد موردون مضافون بعد',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final contact = filteredList[index];
        final isDebt = contact.balanceSyp < 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: type == ContactType.client ? Colors.blue.shade100 : Colors.orange.shade100,
              child: Icon(
                type == ContactType.client ? Icons.person : Icons.store,
                color: type == ContactType.client ? Colors.blue.shade900 : Colors.orange.shade900,
              ),
            ),
            title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('هاتف: ${contact.phone.isNotEmpty ? contact.phone : "غير محدد"}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${contact.balanceSyp.abs().toStringAsFixed(0)} ل.س',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: contact.balanceSyp == 0
                        ? Colors.grey
                        : (isDebt ? Colors.red : Colors.green),
                  ),
                ),
                Text(
                  contact.balanceSyp == 0
                      ? 'متزن'
                      : (isDebt ? 'مطلوب منه' : 'له عندنا'),
                  style: TextStyle(
                    fontSize: 11,
                    color: contact.balanceSyp == 0
                        ? Colors.grey
                        : (isDebt ? Colors.red : Colors.green),
                  ),
                ),
              ],
            ),
            onTap: () {
              // سيتم الربط هنا بصفحة كشف حساب التفصيلي للعميل/المورد
            },
          ),
        );
      },
    );
  }
}
