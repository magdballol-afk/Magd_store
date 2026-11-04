import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للنَسخ
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'database/database_helper.dart';
import 'screens/add_product_screen.dart';
import 'screens/cash_journal_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/products_screen.dart';
import 'screens/new_invoice_screen.dart';
import 'screens/smart_report_screen.dart';
import 'services/backup_service.dart';
import 'services/fiscal_year_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // فحص هل التطبيق مرخص ومفعل مسبقاً على هذا الجهاز
  bool isLicensed = await LicenseHelper.isAppLicensed();

  runApp(MyApp(isLicensed: isLicensed));
}

class MyApp extends StatelessWidget {
  final bool isLicensed;

  const MyApp({Key? key, required this.isLicensed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المبيعات والمستودع',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
      ),
      home: isLicensed ? const MainHomeScreen() : const LicenseActivationScreen(),
    );
  }
}

// =======================================================
// 🔐 المساعد المسؤول عن قراءة Device ID والتحقق
// =======================================================
class LicenseHelper {
  static Future<bool> isAppLicensed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_licensed') ?? false;
  }

  // جلب معرف الجهاز الفريد
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown_device';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      }
    } catch (e) {
      deviceId = 'error_id';
    }
    return deviceId;
  }

  // عملية التفعيل والتحقق القسري لمعرف جهازك واسم المستخدم
  static Future<String> activateApp(String username, String password) async {
    try {
      String currentDevice = await getDeviceId();

      // التحقق القسري لحسابك مع ربطه الحصري بمعرف جهازك HONORNIC-L42
      if (username.trim() == "basel" && password.trim() == "basel123") {
        
        if (currentDevice == "HONORNIC-L42") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_licensed', true);
          await prefs.setString('activated_device', currentDevice);
          return "SUCCESS";
        } else {
          return "هذا الحساب مرتبط بجهاز آخر (HONORNIC-L42) ولا يمكن تشغيله على هذا الهاتف!";
        }

      } else if (username.trim() == "admin" && password.trim() == "admin123") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_licensed', true);
        return "SUCCESS";
      } else {
        return "بيانات الدخول غير صحيحة أو غير مصرح لك";
      }
    } catch (e) {
      return "خطأ في التفعيل: $e";
    }
  }
}

// =======================================================
// 🔐 شاشة التفعيل التي تعرض معرف الجهاز للزبون
// =======================================================
class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({Key? key}) : super(key: key);

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  String _deviceId = 'جاري جلب معرف الجهاز...';

  @override
  void initState() {
    super.initState();
    _loadDeviceIdentifier();
  }

  Future<void> _loadDeviceIdentifier() async {
    String id = await LicenseHelper.getDeviceId();
    setState(() {
      _deviceId = id;
    });
  }

  void _handleActivation() async {
    if (_userController.text.trim().isEmpty || _passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة السر')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String result = await LicenseHelper.activateApp(
      _userController.text,
      _passController.text,
    );

    setState(() => _isLoading = false);

    if (result == "SUCCESS") {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainHomeScreen()),
      );
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('فشل التفعيل'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('موافق'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0277BD).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phonelink_lock_rounded, size: 60, color: Color(0xFF0277BD)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "تفعيل نسخة التطبيق",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "أرسل كود الجهاز التالي للدعم الفني للحصول على بيانات الدخول الخاصة بك",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // صندوق عرض معرف الجهاز مع زر النسخ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("معرف الجهاز (Device ID):", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                _deviceId,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF0277BD)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _deviceId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ معرف الجهاز بنجاح!')),
                            );
                          },
                          tooltip: 'نسخ المعرف',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: "اسم المستخدم",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "كلمة السر",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleActivation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0277BD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "تفعيل الآن",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// الشاشة الرئيسية المعتادة لتطبيقك
// =======================================================
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  String _exchangeRateText = 'جاري جلب أسعار الصرف...';

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  // جلب نشرة أسعار الصرف (نشرة الصرف)
  Future<void> _fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double? sypRate = data['rates']['SYP'] ?? data['rates']['SYP']?.toDouble();
        if (sypRate != null && mounted) {
          setState(() {
            _exchangeRateText = '1 دولار = ${sypRate.toStringAsFixed(2)} ليرة سورية';
          });
        } else if (mounted) {
          setState(() {
            _exchangeRateText = 'نشرة الصرف: متوفرة';
          });
        }
      } else {
        if (mounted) setState(() => _exchangeRateText = 'تعذر جلب أسعار الصرف');
      }
    } catch (e) {
      if (mounted) setState(() => _exchangeRateText = 'خطأ في الاتصال بالإنترنت');
    }
  }

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
            onTap: () async {
              Navigator.pop(context);
              await BackupService.createAndShareBackup(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined, color: Color(0xFF26A69A)),
            title: const Text('استرجاع نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('استعادة البيانات من ملف سابق'),
            onTap: () async {
              Navigator.pop(context);
              await BackupService.restoreBackup(context);
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
              FiscalYearService.showRolloverDialog(context);
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
          // عرض صورة أو شعار mz المعتاد في أعلى لوحة التحكم
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/mz.png', // مسار صورة الشعار mz
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.show_chart, color: Color(0xFF0277BD)),
                      const SizedBox(width: 8),
                      Text(_exchangeRateText, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0277BD))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // بطاقة حركة الصندوق اليومية ونشرة الصرف
          _buildDailyProfitCard(),
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
        ],
      ),
    );
  }

  Widget _buildDailyProfitCard() {
    final String todayStr = DateTime.now().toString().split(' ')[0];

    return FutureBuilder<double>(
      future: DatabaseHelper.instance.getDailyTransactions(todayStr).then((list) {
        double total = 0;
        for (var item in list) {
          total += (item['amount'] as num?)?.toDouble() ?? 0.0;
        }
        return total;
      }),
      builder: (context, snapshot) {
        final double dailyVal = snapshot.data ?? 0.0;
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Text('حركة الصندوق اليومية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  dailyVal.toStringAsFixed(2),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required String title, required Color color, required VoidCallback onTap, IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 8)],
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
