import 'package:flutter/material.dart';
import 'screens/add_product_screen.dart';
import 'screens/smart_report_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المبيعات والمستودع',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // قائمة الشاشات المرتبطة بالشريط السفلي
  final List<Widget> _screens = [
    const DashboardScreenContent(), // الشاشة الرئيسية
    const InvoicesScreenPlaceholder(), // شاشة الفواتير
    const ProductsScreenPlaceholder(), // شاشة المنتجات
    const SmartReportScreen(), // شاشة التقارير
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
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'الفواتير',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'المنتجات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'التقارير',
            ),
          ],
        ),
      ),
    );
  }
}

// محتوى الواجهة الرئيسية (Dashboard)
class DashboardScreenContent extends StatelessWidget {
  const DashboardScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // الهيدر المتموج العلوي
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إدارة المبيعات والمستودع',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'تحليلات الذكاء الاصطناعي اليومية',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // الإحصائيات والأرقام الرئيسية
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'إحصائيات المبيعات اليومية',
                            value: '150,000 ل.س',
                            badgeText: '✨ زيادة 12% عن أمس',
                            badgeColor: Colors.green.shade50,
                            badgeTextColor: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'المخزون الحالي',
                            value: '2,300 قطعة',
                            badgeText: '⚠️ قارب على الانتهاء لـ 5 منتجات',
                            badgeColor: Colors.orange.shade50,
                            badgeTextColor: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'فواتير اليوم',
                            value: '45 فاتورة',
                            badgeText: '📊 أعلى نشاط بين 4-6 م',
                            badgeColor: Colors.blue.shade50,
                            badgeTextColor: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'حسابات العملاء',
                            value: '8,900 ل.س',
                            badgeText: '💡 اقتراح: تواصل للتجميع',
                            badgeColor: Colors.purple.shade50,
                            badgeTextColor: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // قسم إجراءات سريعة
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'إجراءات سريعة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.receipt_long, size: 18),
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
                            icon: const Icon(Icons.inventory_2_outlined, size: 18),
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
                            onPressed: () {},
                            icon: const Icon(Icons.person_outline, size: 18),
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
                            icon: const Icon(Icons.analytics_outlined, size: 18),
                            label: const Text('تقرير ذكي'),
                            style: _buttonStyle(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // تحليل AI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'تحليل AI للمبيعات الأخيرة',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text('أعلى مبيعات للأسبوع', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '📈 الرسم البياني التفاعلي متاح بعد ربط قاعدة البيانات',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
        ),
      ),
    );
  }

  static ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0284C7),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    );
  }

  Widget _buildStatCard({
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 10, color: badgeTextColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// شاشات مؤقتة للتبويب السفلي لحين إكمالها
class InvoicesScreenPlaceholder extends StatelessWidget {
  const InvoicesScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الفواتير', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: const Center(
        child: Text('شاشة سجل الفواتير (سيتم تطويرها بالخطوة القادمة)', style: TextStyle(fontSize: 15)),
      ),
    );
  }
}

class ProductsScreenPlaceholder extends StatelessWidget {
  const ProductsScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة المنتجات والمخزون', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0284C7),
      ),
      body: const Center(
        child: Text('شاشة المنتجات والمخزون (سيتم تطويرها بالخطوة القادمة)', style: TextStyle(fontSize: 15)),
      ),
    );
  }
}
