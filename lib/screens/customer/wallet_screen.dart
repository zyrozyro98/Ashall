import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class WalletScreen extends StatelessWidget {
  final String userId;
  WalletScreen({super.key, required this.userId});

  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("محفظة أسهل"), backgroundColor: AshallTheme.primaryColor),
      body: Column(
        children: [
          // Balance Card
          Container(
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.all(15),
            decoration: AshallTheme.buttonDecoration,
            child: Column(
              children: [
                const Text("رصيدك الحالي", style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 10),
                StreamBuilder(
                  stream: _db.getUserStream(userId), // Assuming this exists or create it
                  builder: (context, snapshot) {
                    double balance = 0.0;
                    if (snapshot.hasData) balance = (snapshot.data!.data() as Map<String, dynamic>?)?['balance'] ?? 0.0;
                    return Text("$balance AED", style: const TextStyle(color: AshallTheme.secondaryColor, fontSize: 36, fontWeight: FontWeight.bold));
                  },
                ),
              ],
            ),
          ),
          
          ElevatedButton.icon(
            onPressed: () => _showRechargeDialog(context),
            icon: const Icon(Icons.add_circle, color: AshallTheme.secondaryColor),
            label: const Text("شحن رصيد التطبيق", style: TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("سجل العمليات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          
          Expanded(
            child: StreamBuilder<List<AppTransaction>>(
              stream: _db.getUserTransactions(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final txs = snapshot.data!;
                return ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, i) {
                    final tx = txs[i];
                    return ListTile(
                      leading: Icon(tx.type == TransactionType.recharge ? Icons.arrow_upward : Icons.arrow_downward, color: tx.type == TransactionType.recharge ? Colors.green : Colors.red),
                      title: Text(tx.type == TransactionType.recharge ? "طلب شحن" : "دفع طلب"),
                      subtitle: Text("كود: ${tx.referenceNumber}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${tx.amount} AED", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(tx.status.name, style: TextStyle(color: tx.status == TransactionStatus.approved ? Colors.green : (tx.status == TransactionStatus.pending ? Colors.orange : Colors.red), fontSize: 12)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRechargeDialog(BuildContext context) {
    final amountC = TextEditingController();
    final refC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تقديم طلب شحن"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("قم بتحويل المبلغ إلى:\nيوسف زهير (771831482)\nثم أدخل البيانات هنا:", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AshallTheme.primaryColor)),
            const SizedBox(height: 15),
            PremiumTextField(label: "المبلغ", controller: amountC),
            const SizedBox(height: 10),
            PremiumTextField(label: "رقم الحوالة / الايصال", controller: refC),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          PremiumButton(
            text: "إرسال الطلب",
            onPressed: () async {
              await _db.requestRecharge(AppTransaction(
                id: '', 
                userId: userId, 
                amount: double.tryParse(amountC.text) ?? 0.0, 
                type: TransactionType.recharge, 
                status: TransactionStatus.pending, 
                referenceNumber: refC.text, 
                timestamp: DateTime.now()
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال طلب الشحن، بانتظار تأكيد المسؤول")));
            },
          ),
        ],
      ),
    );
  }
}
