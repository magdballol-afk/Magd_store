import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// استيراد الشاشات
import 'screens/products_screen.dart';
import 'screens/new_invoice_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/cash_journal_screen.dart';
import 'screens/smart_report_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة المحل',
      debugShowCheckedModeBanner: false,
      
      // إعدادات اللغة العربية والاتجاه من اليمين لليسار (RTL)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      locale: const Locale('ar', 'SA'),

      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              title: 'فاتورة جديدة',
              icon: Icons.add_shopping_cart,
              color: Colors.blue,
              // السطر المصحح بدون const
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewInvoiceScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'إدارة المنتجات',
              icon: Icons.inventory_2,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductsScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'سجل الفواتير',
              icon: Icons.receipt_long,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoicesScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'العملاء والموردون',
              icon: Icons.people,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactsScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'الصندوق والمالية',
              icon: Icons.account_balance_wallet,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashJournalScreen()),
              ),
            ),
            _buildMenuCard(
              context,
              title: 'التقارير الذكية',
              icon: Icons.bar_chart,
              color: Colors.redAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmartReportScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
