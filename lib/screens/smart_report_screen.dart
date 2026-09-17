import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SmartReportScreen extends StatefulWidget {
  const SmartReportScreen({super.key});

  @override
  State<SmartReportScreen> createState() => _SmartReportScreenState();
}

class _SmartReportScreenState extends State<SmartReportScreen> {
  bool _isLoading = true;
  double _totalMonthlySales = 0.0;
  String _topSellingProduct = 'جاري التحليل...';
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. حساب إجمالي مبيعات الشهر الحالي
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final salesResult = await db.rawQuery(
        "SELECT SUM(total_amount) as total FROM sales_invoices WHERE date >= ?",
        [firstDayOfMonth],
      );
      final total = salesResult.first['total'];
      _totalMonthlySales = (total != null) ? (total as num).toDouble() : 0.0;

      // 2. تحديد عدد المواد المخزونها منخفض (أقل من 5 قطع مثلاً)
      final lowStockResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM products WHERE stock_quantity <= 5",
      );
      _lowStockCount = Sqflite.firstIntValue(lowStockResult) ?? 0;

      // 3. تجديد اسم المنتج الأكثر مبيعاً
      final topProductResult = await db.rawQuery('''
        SELECT p.name, SUM(ii.quantity) as total_qty
        FROM invoice_items ii
        JOIN products p ON p.id = ii.product_id
        GROUP BY ii.product_id
        ORDER BY total_qty DESC
        LIMIT 1
      ''');

      if (topProductResult.isNotEmpty) {
        _topSellingProduct = topProductResult.first['name'] as String;
      } else {
        _topSellingProduct = 'لا توجد حركة مبيعات كافية';
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0284C7);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        appBar: AppBar(
          title: const Text('تقرير ذكي - تحليل المبيعات', style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchReportData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بطاقة ملخص المبيعات
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إجمالي مبيعات الشهر الحالي', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(
                              '${_totalMonthlySales.toStringAsFixed(0)} ل.س',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(Icons.insights, color: Colors.greenAccent, size: 20),
                                SizedBox(width: 6),
                                Text('تحديث تلقائي للمؤشرات الماليّة', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('تحليلات الذكاء الاصطناعي والمخزون', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 10),

                      _buildInsightCard(
                        icon: Icons.lightbulb_outline,
                        color: Colors.amber,
                        title: 'المنتج الأكثر مبيعاً',
                        description: 'المنتج الأكثر طلباً هو ($_topSellingProduct). يُوصى بتوفير كميات إضافية.',
                      ),
                      const SizedBox(height: 10),

                      _buildInsightCard(
                        icon: Icons.warning_amber_rounded,
                        color: _lowStockCount > 0 ? Colors.redAccent : Colors.green,
                        title: 'تنبيه النواقص والمخزون',
                        description: _lowStockCount > 0
                            ? 'هناك $_lowStockCount مواد أوشكت على النفاد (المخزون أقل من 5 قطع).'
                            : 'حالة المخزون ممتازة، لا توجد مواد قريبة من النفاد.',
                      ),
                      const SizedBox(height: 10),

                      _buildInsightCard(
                        icon: Icons.access_time,
                        color: Colors.blue,
                        title: 'نصيحة التشغيل',
                        description: 'قم بمراجعة كشوفات حركات المواد أسبوعياً لمطابقة الأرباح والسيولة النقديّة.',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
