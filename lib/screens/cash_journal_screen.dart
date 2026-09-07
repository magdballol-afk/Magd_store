import 'package:flutter/material.dart';

class CashJournalScreen extends StatefulWidget {
  const CashJournalScreen({Key? key}) : super(key: key);

  @override
  State<CashJournalScreen> createState() => _CashJournalScreenState();
}

class _CashJournalScreenState extends State<CashJournalScreen> {
  DateTime selectedDate = DateTime.now();

  final TextEditingController receivedController = TextEditingController();
  final TextEditingController paidController = TextEditingController();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController statementController = TextEditingController();

  // قاعدة بيانات مؤقتة لتخزين الحركات حسب التاريخ (YYYY-MM-DD)
  Map<String, List<Map<String, dynamic>>> dailyTransactions = {};

  String get dateKey =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  List<Map<String, dynamic>> get currentDayList =>
      dailyTransactions[dateKey] ?? [];

  void _addEntry() {
    double received = double.tryParse(receivedController.text) ?? 0.0;
    double paid = double.tryParse(paidController.text) ?? 0.0;
    String account = accountController.text.trim();
    String statement = statementController.text.trim();

    if (account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الحساب')),
      );
      return;
    }

    if (received == 0 && paid == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال قيمة للمقبوضات أو المدفوعات')),
      );
      return;
    }

    setState(() {
      if (dailyTransactions[dateKey] == null) {
        dailyTransactions[dateKey] = [];
      }
      dailyTransactions[dateKey]!.add({
        'received': received,
        'paid': paid,
        'account': account,
        'statement': statement,
      });

      // تفريغ حقول الإدخال
      receivedController.clear();
      paidController.clear();
      accountController.clear();
      statementController.clear();
    });
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  double get totalReceived =>
      currentDayList.fold(0.0, (sum, item) => sum + (item['received'] as double));

  double get totalPaid =>
      currentDayList.fold(0.0, (sum, item) => sum + (item['paid'] as double));

  double get netBalance => totalReceived - totalPaid;

  @override
  void dispose() {
    receivedController.dispose();
    paidController.dispose();
    accountController.dispose();
    statementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0277BD),
        centerTitle: true,
        title: const Text('إدخال وتعديل يومية صندوق', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // شريط اختيار والتنقل بين الأيام
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0277BD)),
                      tooltip: 'اليوم السابق',
                      onPressed: () => _changeDate(-1),
                    ),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF0277BD), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            dateKey,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF0277BD)),
                      tooltip: 'اليوم التالي',
                      onPressed: () => _changeDate(1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // حقول الإدخال
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: receivedController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: 'مقبوضات',
                              prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: paidController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: 'مدفوعات',
                              prefixIcon: const Icon(Icons.arrow_upward, color: Colors.red),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: accountController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'اسم الحساب (العميل / المورد / البند)',
                        prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF0277BD)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: statementController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'البيان / ملاحظات',
                        prefixIcon: const Icon(Icons.note, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0277BD),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                        label: const Text('إضافة الحركة الصندوقية', style: TextStyle(color: Colors.white, fontSize: 16)),
                        onPressed: _addEntry,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // جدول حركات اليوم
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('حركات اليوم المسجلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    currentDayList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('لا توجد حركات مسجلة لهذا اليوم', style: TextStyle(color: Colors.grey))),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentDayList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = currentDayList[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item['account'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(item['statement'].isEmpty ? 'بدون بيان' : item['statement']),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (item['received'] > 0)
                                      Text('+${item['received']} ل.س', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    if (item['paid'] > 0)
                                      Text('-${item['paid']} ل.س', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ملخص الحركة
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المقبوضات:'),
                        Text('${totalReceived.toStringAsFixed(1)} ل.س', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إجمالي المدفوعات:'),
                        Text('${totalPaid.toStringAsFixed(1)} ل.س', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('صافي حركة اليوم:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '${netBalance.toStringAsFixed(1)} ل.س',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: netBalance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
