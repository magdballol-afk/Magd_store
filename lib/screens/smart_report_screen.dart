import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SmartReportScreen extends StatefulWidget {
  const SmartReportScreen({super.key});

  @override
  State<SmartReportScreen> createState() => _SmartReportScreenState();
}

class _SmartReportScreenState extends State<SmartReportScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _expiryReportList = [];

  @override
  void initState() {
    super.initState();
    _fetchExpiryReport();
  }

  Future<void> _fetchExpiryReport() async {
    setState(() => _isLoading = true);
    try {
      // استدعاء دالة تقرير الصلاحيات من DatabaseHelper
      final report = await DatabaseHelper.instance.getExpiryReport();
      setState(() {
        _expiryReportList = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // دالة لتحديد اللون بناءً على الفرق بين تاريخ اليوم وتاريخ انتهاء الصلاحية
  Color _getExpiryColor(String expiryDateStr) {
    try {
      DateTime expiryDate = DateTime.parse(expiryDateStr);
      DateTime now = DateTime.now();
      int differenceDays = expiryDate.difference(now).inDays;

      if (differenceDays < 30) {
        return Colors.red; // منتهي أو ينتهي خلال أقل من شهر (خطير)
      } else if (differenceDays <= 90) {
        return Colors.amber.shade700; // ينتهي خلال 3 أشهر (تحذير)
      } else {
        return Colors.green; // آمن (أبعد من 3 أشهر)
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getExpiryStatusText(String expiryDateStr) {
    try {
      DateTime expiryDate = DateTime.parse(expiryDateStr);
      DateTime now = DateTime.now();
      int differenceDays = expiryDate.difference(now).inDays;

      if (differenceDays < 0) {
        return 'منتهي الصلاحية!';
      } else if (differenceDays < 30) {
        return 'ينتهي خلال $differenceDays يوم (قريب جداً)';
      } else if (differenceDays <= 90) {
        return 'ينتهي خلال ${(_expiryReportList.isNotEmpty ? differenceDays ~/ 30 : 1)} أشهر';
      } else {
        return 'صلاحية آمنة';
      }
    } catch (e) {
      return 'تاريخ غير متوفر';
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
          title: const Text('مراقب تواريخ الصلاحية الذكي', style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchExpiryReport,
                child: _expiryReportList.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Text(
                              'لا توجد مواد مسجلة بتواريخ صلاحية حالياً',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: _expiryReportList.length,
                        itemBuilder: (context, index) {
                          final item = _expiryReportList[index];
                          final productName = item['product_name'] ?? 'مادة غير معروفة';
                          final expiryDate = item['expiry_date'] ?? '';
                          final quantity = item['quantity'] ?? 0;
                          final supplierName = item['supplier_name'] ?? 'مورد عام';

                          Color statusColor = _getExpiryColor(expiryDate);
                          String statusText = _getExpiryStatusText(expiryDate);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // مؤشر لوني جانبي للدلالة على حالة الصلاحية
                                  Container(
                                    width: 6,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'الكمية بالدفعة: $quantity | المورد: $supplierName',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'الانتهاء: $expiryDate',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                            ),
                                            Text(
                                              statusText,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
