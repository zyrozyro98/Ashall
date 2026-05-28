import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/system_settings_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';
import '../../models/transaction.dart';
import '../../models/order.dart';
import '../../widgets/premium_ui.dart';

// Import Admin Modules
import 'modules/user_management.dart';
import 'modules/product_moderation.dart';
import 'modules/settings_module.dart';
import '../customer/support_chat_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DatabaseService _db = DatabaseService();
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<String> _titles = [
    "الرئيسية والإحصائيات",
    "إدارة المستخدمين",
    "إدارة المنتجات",
    "المعاملات المالية",
    "مركز الدعم الفني",
    "طلبات النظام",
    "إعدادات التطبيق",
    "توثيق الحسابات الذكي"
  ];

  List<AppOrder> _overdueOrders = [];
  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();
    _startWatchdog();
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startWatchdog() {
    _watchdogTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkOverdueOrders();
    });
    // Initial check
    Future.delayed(const Duration(seconds: 5), _checkOverdueOrders);
  }

  void _checkOverdueOrders() async {
    if (!mounted) return;
    final settings = Provider.of<SystemSettingsProvider>(context, listen: false).settings;
    final timeout = settings.orderConfirmationTimeoutMinutes;

    final snapshot = await FirebaseFirestore.instance.collection('orders')
        .where('status', isEqualTo: OrderStatus.pending.index)
        .get();

    final now = DateTime.now();
    List<AppOrder> overdue = [];

    for (var doc in snapshot.docs) {
      final order = AppOrder.fromMap(doc.data(), doc.id);
      final diff = now.difference(order.timestamp).inMinutes;
      if (diff >= timeout) {
        overdue.add(order);
      }
    }

    if (overdue.length > _overdueOrders.length) {
      // New overdue orders!
      _showOverdueAlert(overdue.length);
    }

    if (mounted) {
      setState(() {
        _overdueOrders = overdue;
      });
    }
  }

  void _showOverdueAlert(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("⚠️ تنبيه: يوجد $count طلبات بانتظار التأكيد تجاوزت الوقت المسموح!"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: "عرض",
          textColor: Colors.white,
          onPressed: () {
            _pageController.jumpToPage(5);
            setState(() => _selectedIndex = 5);
          },
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminHeader(),
          const SizedBox(height: 25),
          
          // Stats Row
          _buildQuickStats(),
          const SizedBox(height: 30),
          
          // Chart Section
          const PremiumSectionTitle(title: "أداء المبيعات والنمو", subtitle: "إحصائيات الإيرادات خلال الأسبوع الحالي"),
          const SizedBox(height: 15),
          _buildRevenueChart(),
          const SizedBox(height: 30),
          
          // Radar Monitor (Mini version)
          const PremiumSectionTitle(title: "مراقب الرادار الحي", subtitle: "توزيع الطلبات جغرافياً وحسب الحالة"),
          const SizedBox(height: 15),
          _buildOrderDistributionPie(),
          const SizedBox(height: 30),
          
          const PremiumSectionTitle(title: "إجراءات سريعة", subtitle: "إدارة النظام بضغطة واحدة"),
          const SizedBox(height: 15),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(10, 25, 25, 10),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
                        if (value >= 0 && value < days.length) {
                          return Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1200), FlSpot(1, 1900), FlSpot(2, 1500), 
                      FlSpot(3, 2800), FlSpot(4, 2100), FlSpot(5, 3500), FlSpot(6, 3200),
                    ],
                    isCurved: true,
                    color: AshallTheme.primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AshallTheme.primaryColor.withValues(alpha: 0.3), AshallTheme.primaryColor.withValues(alpha: 0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDistributionPie() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(value: 40, color: AshallTheme.primaryColor, title: '40%', radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  PieChartSectionData(value: 25, color: Colors.teal, title: '25%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  PieChartSectionData(value: 20, color: Colors.orange, title: '20%', radius: 35, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  PieChartSectionData(value: 15, color: Colors.red, title: '15%', radius: 30, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPieLegend("تم التوصيل", AshallTheme.primaryColor),
              _buildPieLegend("قيد التحضير", Colors.teal),
              _buildPieLegend("بانتظار المندوب", Colors.orange),
              _buildPieLegend("ملغي", Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshallTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 18)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOverview(),               // Index 0: Metrics & Charts
          const AdminUserManagement(),           // Index 1: Users
          const AdminProductModeration(),        // Index 2: Products
          _buildFinanceManagement(),             // Index 3: Wallets
          _buildSupportManagement(),             // Index 4: Chats
          _buildOrderManagement(),               // Index 5: Orders
          const AdminSettingsModule(),           // Index 6: Settings
          _buildVerificationMonitor(),           // Index 7: Smart Verify
        ],
      ),
    );
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),
                _drawerItem(0, "لوحة التحكم", Icons.grid_view_rounded),
                _drawerItem(1, "إدارة المستخدمين", Icons.people_rounded),
                _drawerItem(2, "المخزون والمنتجات", Icons.inventory_2_rounded),
                _drawerItem(5, "طلبات النظام", Icons.receipt_long_rounded),
                _drawerItem(3, "المعاملات المالية", Icons.account_balance_wallet_rounded, badgeCount: true),
                _drawerItem(4, "الدعم المباشر", Icons.forum_rounded),
                _drawerItem(7, "توثيق الحسابات الذكي", Icons.verified_user_rounded),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Divider(),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AshallTheme.primaryColor),
                  title: const Text("الإعدادات"),
                  onTap: () {
                    _pageController.jumpToPage(6);
                    setState(() => _selectedIndex = 6);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: PremiumButton(
              text: "خروج آمن", 
              icon: Icons.logout_rounded,
              secondary: true,
              onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 70, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF001A33),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PremiumAvatar(name: "مدير النظام", size: 70, isOnline: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withValues(alpha: 0.5))),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 5),
                    Text("النظام يعمل", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("لوحة القيادة المركزية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1)),
          const Text("Super Admin Privilege", style: TextStyle(color: AshallTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, String title, IconData icon, {bool badgeCount = false}) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        selectedTileColor: AshallTheme.primaryColor.withValues(alpha: 0.08),
        leading: badgeCount 
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('transactions')
                  .where('status', isEqualTo: TransactionStatus.pending.index)
                  .snapshots(),
              builder: (context, snap) {
                int count = snap.hasData ? snap.data!.docs.length : 0;
                return Stack(
                  children: [
                    Icon(icon, color: isSelected ? AshallTheme.primaryColor : Colors.grey[600]),
                    if (count > 0)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: AshallTheme.secondaryColor, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                );
              },
            )
          : Icon(icon, color: isSelected ? AshallTheme.primaryColor : Colors.grey[600]),
        title: Text(title, style: TextStyle(
          color: isSelected ? AshallTheme.primaryColor : AshallTheme.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontFamily: GoogleFonts.cairo().fontFamily,
        )),
        onTap: () {
          setState(() => _selectedIndex = index);
          _pageController.jumpToPage(index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFinanceManagement() {
    return Column(
      children: [
        const PremiumSectionTitle(title: "المعاملات المالية والتحقق", icon: Icons.account_balance_wallet_rounded),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transactions')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد معاملات حالياً"));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc = snap.data!.docs[i];
                  final tx = AppTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  bool isPending = tx.status == TransactionStatus.pending;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: isPending ? Colors.orange.withValues(alpha: 0.3) : Colors.transparent, width: 1.5),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      shape: const RoundedRectangleBorder(side: BorderSide.none), // removes border on expand
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTransactionColor(tx.type).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getTransactionIcon(tx.type), color: _getTransactionColor(tx.type), size: 22),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${tx.amount} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                          _getTransactionTypeLabel(tx.type),
                        ],
                      ),
                      subtitle: FutureBuilder(
                        future: _db.getUserProfile(tx.userId),
                        builder: (context, userSnap) {
                          final userName = userSnap.data?.name ?? "جاري التحميل...";
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(userName, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        },
                      ),
                      trailing: isPending 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _db.rejectTransaction(tx.id),
                                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.close_rounded, color: Colors.red, size: 18)),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _db.approveTransaction(tx.id, tx.userId, tx.amount),
                                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.check_rounded, color: Colors.green, size: 18)),
                              ),
                            ],
                          )
                        : PremiumBadge(
                            text: tx.status == TransactionStatus.approved ? "مكتمل" : "مرفوض", 
                            color: tx.status == TransactionStatus.approved ? Colors.green : Colors.red
                          ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("رقم المرجع:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(tx.referenceNumber.isNotEmpty ? tx.referenceNumber : "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("تاريخ العملية:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text(tx.timestamp.toString().substring(0, 16), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                ],
                              ),
                              if (tx.note != null && tx.note!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text("ملاحظات:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(tx.note!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                              ],
                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(child: Text("يرجى التأكد من وصول الحوالة البنكية فعلياً قبل الضغط على تأكيد.", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.recharge: return Icons.add_circle_outline_rounded;
      case TransactionType.payment: return Icons.shopping_bag_outlined;
      case TransactionType.withdrawal: return Icons.outbox_rounded;
      case TransactionType.refund: return Icons.settings_backup_restore_rounded;
    }
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.recharge: return Colors.blue;
      case TransactionType.payment: return Colors.green;
      case TransactionType.withdrawal: return Colors.red;
      case TransactionType.refund: return Colors.orange;
    }
  }

  Widget _getTransactionTypeLabel(TransactionType type) {
    String label = "";
    Color color = Colors.grey;
    switch (type) {
      case TransactionType.recharge: label = "شحن محفظة"; color = Colors.blue; break;
      case TransactionType.payment: label = "دفع طلب"; color = Colors.green; break;
      case TransactionType.withdrawal: label = "سحب أرباح"; color = Colors.red; break;
      case TransactionType.refund: label = "استرداد"; color = Colors.orange; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSupportManagement() {
    return Column(
      children: [
        const PremiumSectionTitle(title: "مركز خدمة العملاء والدعم", icon: Icons.support_agent_rounded),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('support_chats').orderBy('lastUpdate', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_rounded, size: 80, color: Colors.grey), SizedBox(height: 10), Text("صندوق الوارد فارغ")]) );

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc = snap.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final unread = data['unreadCount'] ?? 0;
                  final lastMsg = data['lastMessage'] ?? "طلب دعم فني مباشر";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: unread > 0 ? Colors.blue.withValues(alpha: 0.03) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: unread > 0 ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
                    ),
                    child: FutureBuilder(
                      future: _db.getUserProfile(doc.id),
                      builder: (context, userSnap) {
                        final name = userSnap.data?.name ?? "جار التحميل...";
                        final role = userSnap.data?.role.name ?? "";
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          leading: Stack(
                            children: [
                              CircleAvatar(radius: 24, backgroundColor: unread > 0 ? Colors.blue : Colors.grey[200], child: Icon(Icons.person, color: unread > 0 ? Colors.white : Colors.grey)),
                              if (unread > 0)
                                Positioned(
                                  right: 0, bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                    child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                )
                            ],
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: TextStyle(fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.bold, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5)),
                                child: Text(role, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unread > 0 ? Colors.black87 : Colors.grey, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal)),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupportChatScreen(userId: doc.id, adminId: FirebaseFirestore.instance.app.options.projectId == 'ashaal' ? 'admin' : (FirebaseAuth.instance.currentUser?.uid ?? 'admin')))),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getArabicStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return "بانتظار التأكيد";
      case OrderStatus.preparing: return "قيد التحضير";
      case OrderStatus.ready: return "جاهز للاستلام";
      case OrderStatus.pickedUp: return "مع المندوب";
      case OrderStatus.delivered: return "تم التوصيل";
      case OrderStatus.cancelled: return "ملغي";
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.preparing: return Colors.blue;
      case OrderStatus.ready: return Colors.teal;
      case OrderStatus.pickedUp: return AshallTheme.secondaryColor;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  Widget _buildOrderManagement() {
    return Column(
      children: [
        const PremiumSectionTitle(title: "المراقبة الحية للطلبات", icon: Icons.radar_rounded),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return const Center(child: Text("لا توجد طلبات في النظام"));
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc = snap.data!.docs[i];
                  final order = AppOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  bool isOverdue = _overdueOrders.any((o) => o.id == order.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: isOverdue ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
                      border: isOverdue ? Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text("تجاوز الوقت المسموح للتأكيد من المتجر!", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AshallTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_long_rounded, color: AshallTheme.primaryColor, size: 18)),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("رقم الطلب", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                          Text("#${order.id.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  PremiumBadge(text: _getArabicStatus(order.status), color: _getStatusColor(order.status)),
                                ],
                              ),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildOrderStatItem(Icons.storefront_rounded, "المتجر", order.merchantId.substring(0, 5)),
                                  ),
                                  Expanded(
                                    child: _buildOrderStatItem(Icons.person_outline_rounded, "العميل", order.customerId.substring(0, 5)),
                                  ),
                                  Expanded(
                                    child: _buildOrderStatItem(Icons.payments_outlined, "الإجمالي", "${order.totalPrice} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", color: AshallTheme.primaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("مرحباً بك، الأدمن 👋", style: AshallTheme.titleStyle.copyWith(fontSize: 24)),
            Text("إليك نظرة سريعة على أداء المنصة اليوم", style: AshallTheme.subtitleStyle),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AshallTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.shield_outlined, color: AshallTheme.primaryColor, size: 28),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard("المبيعات اليومية", "١,٥٠٠", Icons.trending_up, Colors.green),
          _buildStatCard("الطلبات الجديدة", "١٢", Icons.shopping_bag_outlined, Colors.blue),
          _buildStatCard("شكاوى معلقة", "٣", Icons.warning_amber_rounded, Colors.orange),
          _buildStatCard("مستخدمين نشطين", "٤٥٠", Icons.people_outline, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 15),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      children: [
        _buildActionIcon(Icons.add_moderator_rounded, "حظر مستخدم", Colors.red),
        _buildActionIcon(Icons.notifications_active_rounded, "تنبيه عام", Colors.orange),
        _buildActionIcon(Icons.discount_rounded, "كوبون جديد", Colors.teal),
        _buildActionIcon(Icons.file_copy_rounded, "تقرير اليوم", Colors.indigo),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildVerificationMonitor() {
    return Column(
      children: [
        const PremiumSectionTitle(title: "مراقب التوثيق الذكي", subtitle: "إدارة طلبات تفعيل أرقام الهواتف عبر الواتساب", icon: Icons.verified_user_rounded),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('isPhoneVerified', isEqualTo: false).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green.withValues(alpha: 0.3)),
                      const SizedBox(height: 20),
                      const Text("كل الحسابات موثقة حالياً", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final user = snapshot.data!.docs[index];
                  final userData = user.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: AshallTheme.primaryColor.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AshallTheme.primaryColor)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userData['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(userData['phone'] ?? 'بدون هاتف', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('users').doc(user.id).update({'isPhoneVerified': true});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم توثيق الحساب بنجاح"), backgroundColor: Colors.green));
                          },
                          child: const Text("توثيق الآن", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatItem(IconData icon, String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? Colors.black87)),
      ],
    );
  }
}
