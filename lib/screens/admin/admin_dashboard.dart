import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';
import '../customer/support_chat_screen.dart';
import '../../models/order.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshallTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Enhanced Admin Header
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AshallTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AshallTheme.primaryColor, AshallTheme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80.0, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: AshallTheme.secondaryColor, size: 30),
                          const SizedBox(width: 10),
                          Text("لوحة تحكم الإدارة", style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 26)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text("مرحباً بك، سيطرة كاملة على النظام بين يديك", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Advanced Live Statistics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("الإحصائيات المباشرة", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildCountStatCard("الطلبات", "orders", Icons.shopping_bag, Colors.blue)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildCountStatCard("العملاء", "users", Icons.people, Colors.purple)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildCountStatCard("المنتجات", "products", Icons.inventory_2, Colors.orange)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pending Transactions (Finance)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("طلبات المحفظة المعلقة", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
                      const Icon(Icons.account_balance_wallet, color: AshallTheme.secondaryColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('transactions')
                        .where('status', isEqualTo: TransactionStatus.pending.index)
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyBox("لا توجد طلبات مالية معلقة");
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, i) {
                          final doc = snapshot.data!.docs[i];
                          final tx = AppTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                          return _buildFinanceCard(tx);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Active Support Chats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("محادثات الدعم الفني", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
                      const Icon(Icons.support_agent, color: AshallTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('support_chats')
                        .orderBy('lastUpdate', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyBox("مركز الدعم هادئ، لا يوجد طلبات مساعدة");
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, i) {
                          final doc = snapshot.data!.docs[i];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AshallTheme.secondaryColor.withOpacity(0.2),
                                child: const Icon(Icons.person, color: AshallTheme.secondaryColor),
                              ),
                              title: Text("العميل ID: ${doc.id.substring(0, 5)}...", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text("اضغط للرد على المحادثة أو المتابعة", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => SupportChatScreen(userId: doc.id)));
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Recent Orders Flow
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("أحدث الطلبات القادمة", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
                      const Icon(Icons.receipt_long, color: AshallTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('orders')
                        .orderBy('timestamp', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyBox("لا يوجد حركة طلبات نشطة");
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, i) {
                          final doc = snapshot.data!.docs[i];
                          final order = AppOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                                child: Text("#${order.id.substring(0, 4)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ),
                              title: Text("${order.totalPrice} درهم", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("الحالة: ${order.status.name} | الدفع: ${order.paymentMethod.name}"),
                              trailing: Icon(order.status == OrderStatus.delivered ? Icons.check_circle : Icons.pending, 
                                color: order.status == OrderStatus.delivered ? Colors.green : Colors.orange),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Uses .count().get() API for highly efficient read operations
  Widget _buildCountStatCard(String title, String collection, IconData icon, Color color) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance.collection(collection).count().get(),
      builder: (context, snapshot) {
        String countStr = "...";
        if (snapshot.hasData) countStr = snapshot.data!.count.toString();
        
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(countStr, style: AshallTheme.titleStyle.copyWith(fontSize: 24, color: color)),
              Text(title, style: AshallTheme.subtitleStyle.copyWith(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinanceCard(AppTransaction tx) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.attach_money, color: Colors.green, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("+ ${tx.amount} درهم", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 5),
                  Text("رمز/كود: ${tx.referenceNumber}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  Text("لصالح ID: ${tx.userId.substring(0, 5)}...", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: AshallTheme.accentColor, size: 35),
                  onPressed: () => _db.approveTransaction(tx.id, tx.userId, tx.amount),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 35),
                  onPressed: () {
                    FirebaseFirestore.instance.collection('transactions').doc(tx.id).update({
                      'status': TransactionStatus.rejected.index
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, color: Colors.grey.shade400, size: 50),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
