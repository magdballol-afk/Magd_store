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
        fontFamily: 'Cairo', // أو الخط المستخدم لديك
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

  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // صورة البانر العلوية مع حواف عصرية
          // ==========================================
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

          // ==========================================
          // قسم إجراءات سريعة
          // ==========================================
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

          // ==========================================
          // نشرة أسعار الصرف (3 حقول فقط)
          // ==========================================
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
// ويدجت نشرة أسعار الصرف بـ 3 حقول شاملة موقع الليرة اليوم
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

  double _sypRate = 13900; // USD / SYP (سعر مبيع الليرة السورية من الليرة اليوم)
  double _tryRate = 34.20; // USD / TRY
  double _eurRate = 1.09;  // EUR / USD

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
        _sypRate = prefs.getDouble('rate_syp') ?? 13900;
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

    // 1. جلب سعر الليرة السورية من موقع الليرة اليوم (sp-today.com)
    try {
      final spResponse = await http
          .get(
            Uri.parse('https://sp-today.com'),
            headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
          )
          .timeout(const Duration(seconds: 5));

      if (spResponse.statusCode == 200) {
        final html = spResponse.body;
        // استخراج القيمة باستخدام RegExp للوصول لخانة مبيع الدولار
        final RegExp regExp = RegExp(r'(\d{2,3}\.\d{2})\s*<\s*\/|\b(\d{2,3}\.\d{2})\b');
        final matches = regExp.allMatches(html);
        
        for (var match in matches) {
          String? valStr = match.group(1) ?? match.group(2);
          if (valStr != null) {
            double? parsedVal = double.tryParse(valStr);
            if (parsedVal != null && parsedVal > 50 && parsedVal < 500) {
              // تحويل القيمة الشائعة بالليرة اليوم (مثلاً 139.00 تعني 13900 ل.س)
              _sypRate = parsedVal * 100;
              sypFetched = true;
              break;
            }
          }
        }
      }
    } catch (_) {}

    // 2. جلب أسعار العملات العالمية (التركي واليورو)
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
    await prefs.setDouble('rate_syp', _sypRate);
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
          
          // صف يحتوي على 3 حقول بالضبط مثل الصورة
          Row(
            children: [
              _buildCurrencyTile('USD / SYP', '${_sypRate.toStringAsFixed(0)} ل.س'),
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
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
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
