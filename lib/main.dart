import 'package:flutter/material.dart';

// استيراد الشاشات من مجلد screens
import 'screens/add_product_screen.dart';
import 'screens/smart_report_screen.dart';
import 'screens/products_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/new_invoice_screen.dart';
import 'screens/contacts_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المبيعات والمستودع',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.blue,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: DashboardScreen(),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0284C7),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 1,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Summary Cards Grid
              _buildSummaryGrid(),
              const SizedBox(height: 24),

              // Quick Actions Title
              const Text(
                'إجراءات سريعة',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Actions Grid (الأزرار الأربعة)
              _buildQuickActionsGrid(context),
              const SizedBox(height: 24),

              // AI Analytics Section
              _buildAIAnalyticsCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              Text(
                'إدارة المبيعات والمستودع',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'تحليلات الذكاء الاصطناعي اليومية',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'إحصائيات المبيعات اليومية',
                value: '150,000 ل.س',
                badgeText: '📈 زيادة 12% عن أمس',
                badgeColor: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                title: 'المخزون الحالي',
                value: '2,300 قطعة',
                badgeText: '⚠️ قارب على الانتهاء لـ 5 منتجات',
                badgeColor: const Color(0xFFFEF3C7),
                badgeTextColor: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'فواتير اليوم',
                value: '45 فاتورة',
                badgeText: '📊 أعلى نشاط بين 4-6 م',
                badgeColor: const Color(0xFFE0F2FE),
                badgeTextColor: const Color(0xFF0369A1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                title: 'حسابات العملاء',
                value: '8,900 ل.س',
                badgeText: '💡 اقتراح: تواصل للتجميع',
                badgeColor: const Color(0xFFFEE2E2),
                badgeTextColor: const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 10, color: badgeTextColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // قسم الأزرار الأربعة المصحح
  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewInvoiceScreen()),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 20),
                label: const Text('+ فاتورة جديدة'),
                style: _buttonStyle(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddProductScreen()),
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined, size: 20),
                label: const Text('+ إضافة منتج'),
                style: _buttonStyle(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactsScreen()),
                  );
                },
                icon: const Icon(Icons.person_outline, size: 20),
                label: const Text('حساب عميل'),
                style: _buttonStyle(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SmartReportScreen()),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, size: 20),
                label: const Text('تقرير ذكي'),
                style: _buttonStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أعلى مبيعات للأسبوع', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('تحليل AI للمبيعات الأخيرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'الرسم البياني التفاعلي متاح بعد ربط قاعدة البيانات',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0284C7),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoicesScreen()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'المنتجات'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الفواتير'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
      ],
    );
  }
}
