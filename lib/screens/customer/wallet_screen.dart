import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../providers/system_settings_provider.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class WalletScreen extends StatelessWidget {
  final String userId;
  final bool isWithdrawMode; // If true, it acts as a withdrawal wallet (Merchant/Driver)
  
  WalletScreen({super.key, required this.userId, this.isWithdrawMode = false});

  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SystemSettingsProvider>(context).settings;
    String title = isWithdrawMode ? "محفظة الأرباح" : "محفظة أسهل";
    String actionLabel = isWithdrawMode ? "طلب سحب رصيد" : "شحن رصيد التطبيق";

    return Scaffold(
      appBar: AppBar(
        title: Text(title), 
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Premium Balance Card
          Container(
            padding: const EdgeInsets.all(30),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AshallTheme.premiumGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AshallTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                 Text(isWithdrawMode ? "أرباحك القابلة للسحب" : "رصيدك الحالي", 
                   style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                StreamBuilder(
                  stream: _db.getUserStream(userId),
                  builder: (context, snapshot) {
                    double balance = 0.0;
                    if (snapshot.hasData) {
                      balance = (snapshot.data!.data() as Map<String, dynamic>?)?['balance']?.toDouble() ?? 0.0;
                    }
                    return Text("${balance.toStringAsFixed(2)} ${settings.currencySymbol}", 
                      style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900));
                  },
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PremiumButton(
              text: actionLabel,
              onPressed: () => isWithdrawMode ? _showWithdrawDialog(context) : _showRechargeDialog(context),
            ),
          ),
          
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("سجل العمليات المالية", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Icon(Icons.history_rounded, color: AshallTheme.primaryColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          Expanded(
            child: StreamBuilder<List<AppTransaction>>(
              stream: _db.getUserTransactions(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final txs = snapshot.data!;
                if (txs.isEmpty) return const Center(child: Text("لا توجد عمليات سابقة"));
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: txs.length,
                  itemBuilder: (context, i) {
                    final tx = txs[i];
                    String typeLabel = "";
                    IconData typeIcon;
                    Color typeColor;

                    switch (tx.type) {
                      case TransactionType.recharge:
                        typeLabel = "شحن رصيد";
                        typeIcon = Icons.add_chart_rounded;
                        typeColor = Colors.green;
                        break;
                      case TransactionType.withdrawal:
                        typeLabel = "طلب سحب";
                        typeIcon = Icons.account_balance_rounded;
                        typeColor = Colors.blue;
                        break;
                      case TransactionType.payment:
                        typeLabel = "دفع طلب";
                        typeIcon = Icons.shopping_basket_rounded;
                        typeColor = Colors.orange;
                        break;
                      case TransactionType.refund:
                        typeLabel = "استرداد";
                        typeIcon = Icons.history_rounded;
                        typeColor = Colors.teal;
                        break;
                    }

                    return PremiumCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withValues(alpha: 0.1),
                          child: Icon(typeIcon, color: typeColor, size: 20),
                        ),
                        title: Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(tx.referenceNumber.isNotEmpty ? "مرجع: ${tx.referenceNumber}" : "عملية نظام"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${tx.amount} ${settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            _buildStatusBadge(tx.status),
                          ],
                        ),
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

  Widget _buildStatusBadge(TransactionStatus status) {
    String text = "معلق";
    Color color = Colors.orange;
    if (status == TransactionStatus.approved) {
      text = "مكتمل";
      color = Colors.green;
    } else if (status == TransactionStatus.rejected) {
      text = "مرفوض";
      color = Colors.red;
    }
    return Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold));
  }

  void _showRechargeDialog(BuildContext context) {
    final amountC = TextEditingController();
    final refC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("تقديم طلب شحن رصيد", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("قم بتحويل المبلغ إلى:\nيوسف زهير (771831482)\nثم أدخل البيانات هنا:", 
              textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AshallTheme.primaryColor, fontSize: 13)),
            const SizedBox(height: 20),
            PremiumTextField(label: "المبلغ المراد شحنه", controller: amountC),
            const SizedBox(height: 10),
            PremiumTextField(label: "رقم الحوالة أو الإيصال", controller: refC),
          ],
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          PremiumButton(
            text: "إرسال طلب الشحن",
            onPressed: () async {
              if (amountC.text.isEmpty || refC.text.isEmpty) return;
              await _db.requestRecharge(AppTransaction(
                id: '', 
                userId: userId, 
                amount: double.tryParse(amountC.text) ?? 0.0, 
                type: TransactionType.recharge, 
                status: TransactionStatus.pending, 
                referenceNumber: refC.text, 
                timestamp: DateTime.now()
              ));
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال طلب الشحن، بانتظار التأكيد")));
            },
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final amountC = TextEditingController();
    final bankInfoC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("طلب سحب رصيد", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("أدخل المبلغ وبيانات التحويل المفضلة (اسم البنك/المحفظة والرقم):", 
              textAlign: TextAlign.center, style: TextStyle(color: AshallTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            PremiumTextField(label: "المبلغ المطلوب سحبه", controller: amountC),
            const SizedBox(height: 10),
            PremiumTextField(label: "بيانات التحويل / رقم الحساب", controller: bankInfoC),
          ],
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          PremiumButton(
            text: "تأكيد طلب السحب",
            onPressed: () async {
              double? amount = double.tryParse(amountC.text);
              if (amount == null || amount <= 0 || bankInfoC.text.isEmpty) return;
              
              try {
                await _db.requestWithdrawal(AppTransaction(
                  id: '', 
                  userId: userId, 
                  amount: amount, 
                  type: TransactionType.withdrawal, 
                  status: TransactionStatus.pending, 
                  referenceNumber: 'WITHDRAW', // Static marker
                  note: bankInfoC.text, // Store bank info in note
                  timestamp: DateTime.now()
                ));
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال طلب السحب بنجاح")));
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }
}
