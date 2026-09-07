import 'package:flutter/material.dart';

// استدعاء جميع الشاشات المبرمجة في مجلد screens
import 'screens/invoices_screen.dart';
import 'screens/products_screen.dart';
import 'screens/smart_report_screen.dart';
import 'screens/cash_journal_screen.dart';
import 'screens/new_invoice_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/contacts_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magd Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // قائمة الشاشات المرتبطة بالشريط السفلي
  final List<Widget> _screens = const [
    HomeScreenContent(),    // التبويب 0: الرئيسية
    InvoicesScreen(),       // التبويب 1: الفواتير
    ProductsScreen(),       // التبويب 2: المنتجات
    SmartReportScreen(),    // التبويب 3: التقارير
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0D47A1),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'الفواتير',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'المنتجات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'التقارير',
            ),
          ],
        ),
      ),
    );
  }
}

// محتوى الشاشة الرئيسية (Home Tab)
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المبيعات والمستودع'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة رأسية
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة المبيعات والمستودع',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تحليلات الذكاء الاصطناعي اليومية',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // كروت الإحصائيات السريعة
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard('إحصائيات المبيعات اليومية', '150,000 ل.س', 'زيادة 12% عن أمس', Colors.green),
                _buildStatCard('المخزون الحالي', '2,300 قطعة', 'قارب على الانتهاء لـ 3', Colors.orange),
                _buildStatCard('فواتير اليوم', '45 فاتورة', 'أعلى نشاط بين 4-6', Colors.blue),
                _buildStatCard('حسابات العملاء', '8,900 ل.س', 'اقتراح: تواصل مع 2', Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'إجراءات سريعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // أزرار الإجراءات السريعة
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildActionButton(
                  context,
                  title: 'إضافة منتج +',
                  icon: Icons.add_box,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
                ),
                _buildActionButton(
                  context,
                  title: 'فاتورة جديدة +',
                  icon: Icons.receipt,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewInvoiceScreen())),
                ),
                _buildActionButton(
                  context,
                  title: 'حركة صندوق',
                  icon: Icons.account_balance_wallet,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashJournalScreen())),
                ),
                _buildActionButton(
                  context,
                  title: 'حساب عميل',
                  icon: Icons.person,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subText, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subText, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0277BD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }
}
