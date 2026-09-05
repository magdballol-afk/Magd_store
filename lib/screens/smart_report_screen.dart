import 'package:flutter/material.dart';

class SmartReportScreen extends StatelessWidget {
  const SmartReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        appBar: AppBar(
          title: const Text('تقرير ذكي - تحليل المبيعات', style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: const Color(0xFF0284C7),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الملخص
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
                  children: const [
                    Text('إجمالي مبيعات الشهر', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 8),
                    Text('4,250,000 ل.س', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
                        SizedBox(width: 4),
                        Text('زيادة 15% مقارنة بالشهر السابق', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('تحليلات الذكاء الاصطناعي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 10),

              _buildInsightCard(
                icon: Icons.lightbulb_outline,
                color: Colors.amber,
                title: 'المنتج الأكثر مبيعاً',
                description: 'شامبو بانتين هو الأكثر طلباً هذا الأسبوع. يُوصى بزيادة المخزون.',
              ),
              const SizedBox(height: 10),

              _buildInsightCard(
                icon: Icons.access_time,
                color: Colors.blue,
                title: 'أوقات الذروة',
                description: 'أعلى نسبة مبيعات تسجل يومياً بين الساعة 4:00 مساءً و 7:00 مساءً.',
              ),
              const SizedBox(height: 10),

              _buildInsightCard(
                icon: Icons.warning_amber_rounded,
                color: Colors.redAccent,
                title: 'تنبيه النواقص',
                description: 'هناك 5 منتجات أوشكت على النفاد. يرجى مراجعة قائمة المنتجات.',
              ),
            ],
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
                    color: Colors.black.withOpacity(0.6),
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

