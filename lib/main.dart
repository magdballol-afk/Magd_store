import 'package:sqflite/sqflite.dart';

import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'screens/products_screen.dart';
import 'screens/cash_journal_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/new_invoice_screen.dart';
import 'screens/smart_report_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
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
        useMaterial3: false,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainNavigationScreen(),
      ),
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

  final List<Widget> _screens = [
    const HomeDashboardView(),
    const InvoicesScreen(),
    const ProductsScreen(),
    const SmartReportScreen(),
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
        selectedItemColor: const Color(0xFF0284C7),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'الفواتير'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'المنتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'التقارير'),
        ],
      ),
    );
  }
}

class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  bool _isLoading = true;

  // متغيّرات الإحصائيات المرتبطة بقاعدة البيانات
  double _todaySales = 0.0;
  int _todayInvoicesCount = 0;
  double _totalStockQuantity = 0.0;
  int _lowStockCount = 0;
  double _totalDebts = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // دالة جلب واستعلام الإحصائيات من قاعدة البيانات
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // 1. حساب مبيعات وفواتير اليوم
      final salesResult = await db.rawQuery(
        "SELECT COUNT(*) as count, SUM(total_amount) as total FROM sales_invoices WHERE date LIKE ?",
        ['$todayStr%'],
      );
      if (salesResult.isNotEmpty) {
        _todayInvoicesCount = Sqflite.firstIntValue(salesResult) ?? 0;
        final total = salesResult.first['total'];
        _todaySales = (total != null) ? (total as num).toDouble() : 0.0;
      }

      // 2. حساب إجمالي الكميات بالنواقص في المستودع
      final stockResult = await db.rawQuery(
        "SELECT SUM(stock_quantity) as total_qty, COUNT(CASE WHEN stock_quantity <= 5 THEN 1 END) as low_stock FROM products",
      );
      if (stockResult.isNotEmpty) {
        final qty = stockResult.first['total_qty'];
        _totalStockQuantity = (qty != null) ? (qty as num).toDouble() : 0.0;
        _lowStockCount = Sqflite.firstIntValue(stockResult) ?? 0;
      }

      // 3. حساب إجمالي ديون الحسابات/العملاء
      final debtsResult = await db.rawQuery(
        "SELECT SUM(balance) as total_balance FROM contacts",
      );
      if (debtsResult.isNotEmpty) {
        final balance = debtsResult.first['total_balance'];
        _totalDebts = (balance != null) ? (balance as num).toDouble() : 0.0;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('إدارة المبيعات والمستودع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0284C7),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. بنر الذكاء الاصطناعي
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartReportScreen()));
                        _loadDashboardData();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF0083B0).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('إدارة المبيعات والمستودع', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('تحليلات الذكاء الاصطناعي اليومية', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. شبكة بطاقات الإحصائيات الحقيقية من قاعدة البيانات
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        _buildStatCard(
                          title: 'إحصائيات المبيعات اليومية',
                          value: '${_todaySales.toStringAsFixed(0)} ل.س',
                          badgeText: 'مبيعات اليوم',
                          badgeColor: const Color(0xFFDCFCE7),
                          badgeTextColor: const Color(0xFF15803D),
                          icon: Icons.trending_up,
                          iconColor: const Color(0xFF0D9488),
                        ),
                        _buildStatCard(
                          title: 'المخزون الحالي',
                          value: '${_totalStockQuantity.toStringAsFixed(0)} قطعة',
                          badgeText: _lowStockCount > 0 ? 'قارب الانتهاء لـ $_lowStockCount' : 'المخزون ممتاز',
                          badgeColor: _lowStockCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          badgeTextColor: _lowStockCount > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
                          icon: Icons.assignment_outlined,
                          iconColor: const Color(0xFFD97706),
                        ),
                        _buildStatCard(
                          title: 'فواتير اليوم',
                          value: '$_todayInvoicesCount فاتورة',
                          badgeText: 'عمليات اليوم',
                          badgeColor: const Color(0xFFE0F2FE),
                          badgeTextColor: const Color(0xFF0369A1),
                          icon: Icons.receipt_long_outlined,
                          iconColor: const Color(0xFF0284C7),
                        ),
                        _buildStatCard(
                          title: 'حسابات العملاء',
                          value: '${_totalDebts.toStringAsFixed(0)} ل.س',
                          badgeText: 'إجمالي الأرصدة',
                          badgeColor: const Color(0xFFF3E8FF),
                          badgeTextColor: const Color(0xFF6B21A8),
                          icon: Icons.people_outline,
                          iconColor: const Color(0xFF9333EA),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. عنوان إجراءات سريعة
                    const Text(
                      'إجراءات سريعة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),

                    // 4. أزرار الإجراءات السريعة
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _buildActionButton(
                          title: '+ إضافة منتج',
                          gradient: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsScreen()));
                            _loadDashboardData();
                          },
                        ),
                        _buildActionButton(
                          title: '+ فاتورة جديدة',
                          gradient: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const NewInvoiceScreen()));
                            _loadDashboardData();
                          },
                        ),
                        _buildActionButton(
                          title: 'حركة صندوق',
                          gradient: const [Color(0xFF36D1DC), Color(0xFF5B86E5)],
                          icon: Icons.account_balance_wallet_outlined,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const CashJournalScreen()));
                            _loadDashboardData();
                          },
                        ),
                        _buildActionButton(
                          title: 'حساب عميل',
                          gradient: const [Color(0xFF13E2DA), Color(0xFF04B6D8)],
                          icon: Icons.person_search_outlined,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactsScreen()));
                            _loadDashboardData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ودجت بطاقات الإحصائيات
  Widget _buildStatCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
            child: Text(badgeText, style: TextStyle(fontSize: 10, color: badgeTextColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ودجت أزرار الإجراءات السريعة
  Widget _buildActionButton({
    required String title,
    required List<Color> gradient,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.centerRight, end: Alignment.centerLeft),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: gradient.last.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
            ],
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
