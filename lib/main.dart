import 'screens/add_product_screen.dart';
import 'screens/new_invoice_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/smart_report_screen.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const AiSmartStoreApp());
}

class AiSmartStoreApp extends StatelessWidget {
  const AiSmartStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المبيعات الذكية',
      theme: ThemeData(
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF), // خلفية بيضاء سماوية ناعمة
        body: Column(
          children: [
            // 1. الشريط العلوي المتموج التدرجي
            ClipPath(
              clipper: WaveHeaderClipper(),
              child: Container(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF0F172A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'إدارة المبيعات والمستودع',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'تحليلات الذكاء الاصطناعي اليومية',
                          style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_graph, color: Colors.white, size: 28),
                    )
                  ],
                ),
              ),
            ),

            // 2. محتوى الشاشة المقسم
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  // بطاقات الإحصائيات مع توجيهات AI
                  Row(
                    children: [
                      Expanded(
                        child: _buildAiStatCard(
                          title: 'إحصائيات المبيعات اليومية',
                          value: '150,000 ل.س',
                          aiNotice: '✨ زيادة 12% عن أمس',
                          noticeColor: Colors.green,
                          valueColor: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAiStatCard(
                          title: 'المخزون الحالي',
                          value: '2,300 قطعة',
                          aiNotice: '⚠️ قارب على الانتهاء لـ 5 منتجات',
                          noticeColor: Colors.orange,
                          valueColor: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAiStatCard(
                          title: 'فواتير اليوم',
                          value: '45 فاتورة',
                          aiNotice: '📊 أعلى نشاط بين 4-6 م',
                          noticeColor: Colors.blue,
                          valueColor: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildAiStatCard(
                          title: 'حسابات العملاء',
                          value: '8,900 ل.س',
                          aiNotice: '💡 اقتراح: تواصل للتجميع',
                          noticeColor: Colors.purple,
                          valueColor: const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // الإجراءات السريعة بأزرار متموجة زرقاء
                  const Text('إجراءات سريعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
            Row(
  children: [
    // 1. زر فاتورة جديدة
    Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewInvoiceScreen(),
            ),
          );
        },
        child: _buildGradientButton(
          title: '+ فاتورة جديدة',
          icon: Icons.receipt_long,
        ),
      ),
    ),
    const SizedBox(width: 10),
    // 2. زر إضافة منتج
    Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
        },
        child: _buildGradientButton(
          title: '+ إضافة منتج',
          icon: Icons.inventory_2_outlined,
        ),
      ),
    ),
  ],
),
const SizedBox(height: 20),
      
          
              Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContactsScreen(),
            ),
          );
        },
        child: _buildGradientButton(
          title: 'حساب عميل',
          icon: Icons.person_search_outlined,
        ),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: GestureDetector(
        onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SmartReportScreen()),
      );
        },
        child: _buildGradientButton(
          title: 'تقرير ذكي',
          icon: Icons.analytics_outlined,
        ),
      ),
    ),
  ],
),
const SizedBox(height: 20),


                  // قسم تحليل AI للمبيعات الأخيرة
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('تحليل AI للمبيعات الأخيرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('أعلى مبيعات للأسبوع', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE0F2FE), Color(0xFF0284C7)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '📈 الرسم البياني التفاعلي متاح بعد ربط قاعدة البيانات',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),

        // شريط التنقل السفلي المتموج والمضيء
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الفواتير'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'المنتجات'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'التقارير'),
          ],
        ),
      ),
    );
  }

  // ودجت لإنشاء بطاقة إحصائية مع شارة AI
  Widget _buildAiStatCard({
    required String title,
    required String value,
    required String aiNotice,
    required Color noticeColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: noticeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              aiNotice,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: noticeColor),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت الأزرار التدرجية المتموجة
  Widget _buildGradientButton({required String title, required IconData icon}) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// كلاس خاص برسم الموجة الانسيابية أعلى الشاشة (Clipper)
class WaveHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 30);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
