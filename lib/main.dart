import 'package:flutter/material.dart';
import 'products_screen.dart';
import 'cash_journal_screen.dart';
import 'invoices_screen.dart';
import 'contacts_screen.dart';
import 'new_invoice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // القائمة التي تبدل الشاشات عبر الشريط السفلي
  final List<Widget> _screens = [
    const HomeDashboardView(), // الواجهة الرئيسية (الكروت)
    const ProductsScreen(),    // شاشة المنتجات
    const InvoicesScreen(),    // شاشة الفواتير
    const CashJournalScreen(),  // شاشة الصندوق
    const ContactsScreen(),    // شاشة الجهات (عملاء/موردين)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarThemeData(
            // يتم الاعتماد على أيقونات واضحة لجميع القوائم
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'المنتجات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'الفواتير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'الصندوق',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'الجهات',
          ),
        ],
      ),
    );
  }
}

// كروت الصفحة الرئيسية
class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // كارت إنشاء فاتورة جديدة
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.blue, size: 32),
              title: const Text('إنشاء فاتورة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('إضافة فاتورة بيع أو شراء جديدة'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewInvoiceScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // كارت المنتجات والمخزون
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.amber, size: 32),
              title: const Text('إدارة المنتجات والمخزون', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('عرض وتعديل المكونات وكشف حركاتها'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // كارت دفتر الصندوق
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 32),
              title: const Text('دفتر الصندوق (الخزينة)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('متابعة المقبوضات والمقسوم اليومي'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CashJournalScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // كارت دليل العملاء والموردين
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.people, color: Colors.purple, size: 32),
              title: const Text('العملاء والموردين', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('إدارة الحسابات والأرصدة والذمم'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
