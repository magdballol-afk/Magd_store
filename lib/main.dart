import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/add_product_screen.dart';
import 'screens/cash_journal_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/item_movement_filter_screen.dart';
import 'screens/new_invoice_screen.dart';
import 'screens/products_screen.dart';
import 'screens/smart_report_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المبيعات والمستودع',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      drawer: _buildSideDrawer(context),
      appBar: AppBar(
        title: const Text(
          'إدارة المبيعات والمستودع',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF0277BD),
      ),
      body: _buildDashboardBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesListScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartReportScreen()));
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0277BD),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'الفواتير'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'المنتجات'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'التقارير'),
        ],
      ),
    );
  }

  // القائمة الجانبية (Drawer)
  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0277BD), Color(0xFF00B0FF)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 10),
                const Text(
                  'إدارة المبيعات والمستودع',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'خيارات النظام والنسخ الاحتياطي',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'النسخ الاحتياطي',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF0277BD)),
            title: const Text('إنشاء نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('حفظ قاعدة البيانات محلياً أو مشاركتها'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined, color: Color(0xFF26A69A)),
            title: const Text('استرجاع نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('استعادة البيانات من ملف سابق'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'إدارة الحسابات والسنوات',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.published_with_changes_rounded, color: Color(0xFFE53935)),
            title: const Text('تدوير السنة المالية', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
            subtitle: const Text('ترحيل الأرصدة وإغلاق السنة الحالية'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text('عن التطبيق'),
            subtitle: const Text('الإصدار 1.0.0'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/background.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0277BD), Color(0xFF00B0FF)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'إجراءات سريعة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.1,
            children: [
              _buildActionButton(
                title: '+ إضافة منتج',
                color: const Color(0xFF00ACC1),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));
                },
              ),
              _buildActionButton(
                title: '+ فاتورة جديدة',
                color: const Color(0xFF00B0FF),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NewInvoiceScreen(type: 'sale')));
                },
              ),
              _buildActionButton(
                title: 'حركة صندوق',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF5C6BC0),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CashJournalScreen()));
                },
              ),
              _buildActionButton(
                title: 'حساب عميل',
                icon: Icons.people_outline,
                color: const Color(0xFF26A69A),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const CurrencyRatesCard(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// ويدجت أسعار الصرف بآلية التتبع الديناميكية المباشرة
// =======================================================
class CurrencyRatesCard extends StatefulWidget {
  const CurrencyRatesCard({Key? key}) : super(key: key);

  @override
  State<CurrencyRatesCard> createState() => _CurrencyRatesCardState();
}

class _CurrencyRatesCardState extends State<CurrencyRatesCard> {
  bool _isLoading = false;
  bool _isOfflineData = false;
  String _lastUpdated = 'غير محدّث';

  String _sypSellRateText = '13,900';
  double _tryRate = 34.20;
  double _eurRate = 1.09;

  @override
  void initState() {
    super.initState();
    _loadStoredDataAndFetch();
  }

  Future<void> _loadStoredDataAndFetch() async {
    await _loadFromLocal();
    await _fetchRatesFromApi();
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _sypSellRateText = prefs.getString('rate_syp_text') ?? '13,900';
        _tryRate = prefs.getDouble('rate_try') ?? 34.20;
        _eurRate = prefs.getDouble('rate_eur') ?? 1.09;
        _lastUpdated = prefs.getString('rate_last_updated') ?? 'بيانات مخزنة سابقة';
      });
    } catch (_) {}
  }

  Future<void> _fetchRatesFromApi() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    bool sypFetched = false;
    bool globalFetched = false;

    // جلب سعر المبيع من API sp-today مباشرة بطلب مقترن بترويسات المتصفح
    try {
      final spResponse = await http
          .get(
            Uri.parse('https://sp-today.com/api/cur/usd'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
              'Accept': 'application/json, text/plain, */*',
              'Referer': 'https://sp-today.com/en/currency/us-dollar',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (spResponse.statusCode == 200) {
        final data = json.decode(spResponse.body);
        // التعديل: التأكد من جلب حقل 'sell' للمبيع
        if (data != null && data['sell'] != null) {
          String rawSell = data['sell'].toString();
          if (rawSell.isNotEmpty) {
            _sypSellRateText = rawSell;
            sypFetched = true;
          }
        }
      }
    } catch (_) {}

    // التعديل: تحديث Regex الاحتياطي ليبحث عن "المبيع" Selling Price بدقة أكبر
    if (!sypFetched) {
      try {
        final htmlResponse = await http
            .get(
              Uri.parse('https://sp-today.com/en/currency/us-dollar'),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
              },
            )
            .timeout(const Duration(seconds: 5));

        if (htmlResponse.statusCode == 200) {
          final html = htmlResponse.body;
          // Regex جديد يبحث عن الرقم الموجود داخل class="price" لضمان جلب سعر المبيع الحالي
          final RegExp regSell = RegExp(r'<span class="price">([\d,]+)</span>\s*old');
          final match = regSell.firstMatch(html);
          if (match != null && match.group(1) != null) {
            _sypSellRateText = match.group(1)!;
            sypFetched = true;
          }
        }
      } catch (_) {}
    }

    // جلب التركي واليورو
    try {
      final response = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'];
          _tryRate = (rates['TRY'] as num?)?.toDouble() ?? _tryRate;
          _eurRate = (rates['EUR'] as num?)?.toDouble() ?? _eurRate;
          globalFetched = true;
        }
      }
    } catch (_) {}

    final now = DateTime.now();
    final formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rate_syp_text', _sypSellRateText);
    await prefs.setDouble('rate_try', _tryRate);
    await prefs.setDouble('rate_eur', _eurRate);
    await prefs.setString('rate_last_updated', formattedTime);

    if (mounted) {
      setState(() {
        _lastUpdated = formattedTime;
        _isOfflineData = !(sypFetched || globalFetched);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0277BD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.currency_exchange, color: Color(0xFF0277BD), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'أسعار الصرف اللحظية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_isOfflineData)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off, size: 12, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('أوفلاين', style: TextStyle(fontSize: 11, color: Colors.amber)),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20, color: Colors.grey),
                    onPressed: _isLoading ? null : _fetchRatesFromApi,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // التعديل: تغيير التسمية لتوضيح أنه سعر مبيع
              _buildCurrencyTile('مبيع USD / SYP', 'ل.س $_sypSellRateText'),
              const SizedBox(width: 8),
              _buildCurrencyTile('USD / TRY', '${_tryRate.toStringAsFixed(2)} ₺'),
              const SizedBox(width: 8),
              _buildCurrencyTile('EUR / USD', '\$${_eurRate.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'آخر تحديث: $_lastUpdated',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTile(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0277BD)),
            ),
          ],
        ),
      ),
    );
  }
}
