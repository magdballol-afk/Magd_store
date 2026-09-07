import 'package:flutter/material.dart';
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
      title: 'Magu Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // يمكنك تعديل الخط حسب المتوفر في مشروعك
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

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0277BD),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required IconData badgeIcon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 12, color: badgeTextColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      badgeText,
                      style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر العلوي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF01579B), Color(0xFF0288D1)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة المبيعات والمستودع',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تحليلات الذكاء الاصطناعي اليومية',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // بطاقات الإحصائيات (2x2)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildStatCard(
                    title: 'إحصائيات المبيعات اليومية',
                    value: '150,000 ل.س',
                    badgeText: 'زيادة 12% عن أمس',
                    badgeBgColor: Colors.green.shade50,
                    badgeTextColor: Colors.green.shade700,
                    badgeIcon: Icons.trending_up,
                  ),
                  _buildStatCard(
                    title: 'المخزون الحالي',
                    value: '2,300 قطعة',
                    badgeText: 'قارب على الانتهاء لـ 5 منتجات',
                    badgeBgColor: Colors.amber.shade50,
                    badgeTextColor: Colors.amber.shade900,
                    badgeIcon: Icons.warning_amber_rounded,
                  ),
                  _buildStatCard(
                    title: 'فواتير اليوم',
                    value: '45 فاتورة',
                    badgeText: 'أعلى نشاط بين 4-6 م',
                    badgeBgColor: Colors.blue.shade50,
                    badgeTextColor: Colors.blue.shade700,
                    badgeIcon: Icons.bar_chart,
                  ),
                  _buildStatCard(
                    title: 'حسابات العملاء',
                    value: '8,900 ل.س',
                    badgeText: 'اقتراح: تواصل للتجميع',
                    badgeBgColor: Colors.red.shade50,
                    badgeTextColor: Colors.red.shade700,
                    badgeIcon: Icons.lightbulb_outline,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // قسم إجراءات سريعة
              const Text(
                'إجراءات سريعة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // أزرار الإجراءات السريعة الأربعة
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildQuickActionButton(
                    title: '+ فاتورة جديدة',
                    icon: Icons.receipt_long,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewInvoiceScreen()),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    title: '+ إضافة منتج',
                    icon: Icons.add_box,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddProductScreen()),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    title: 'حساب عميل',
                    icon: Icons.person_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ContactsScreen()),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    title: 'حركة صندوق',
                    icon: Icons.account_balance_wallet,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CashJournalScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0277BD),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'الفواتير'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'المنتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'التقارير'),
        ],
      ),
    );
  }
}
