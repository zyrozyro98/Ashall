import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/system_settings_provider.dart';
import 'active_delivery.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../customer/wallet_screen.dart';
import '../customer/support_chat_screen.dart';
import 'route_optimizer_screen.dart';
import 'available_orders_map_screen.dart';

class DriverDashboard extends StatefulWidget {
  final String uid;
  const DriverDashboard({super.key, required this.uid});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final DatabaseService _db = DatabaseService();
  bool _isOnline = false;
  bool _initializedStatus = false;
  int _activeTab = 0;

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text("تسجيل الخروج", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: const Text("هل تريد بالتأكيد تسجيل الخروج من حساب السائق؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("تراجع")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AshallTheme.primaryColor),
              onPressed: () => Navigator.pop(c, true),
              child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Sign out through AuthService
        await AuthService().signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل تسجيل الخروج: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) setState(() {});
        },
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildDriverHeader(),
          
          SliverToBoxAdapter(
            child: _buildControlTabs(),
          ),

          if (_activeTab == 0 && _isOnline) ...[
            SliverToBoxAdapter(child: _buildEarningsSection()),
            _buildActiveOrdersSliver(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
                child: Row(
                  children: [
                    const Icon(Icons.radar_rounded, color: AshallTheme.primaryColor),
                    const SizedBox(width: 10),
                    const Text("المهمات المتوفرة الآن", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.map_rounded, size: 16, color: Colors.green),
                      label: const Text("رادار الطلبات", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AvailableOrdersMapScreen(uid: widget.uid)));
                      },
                    ),
                  ],
                ),
              ),
            ),
            _buildOrderStream(),
          ] else if (_activeTab == 0 && !_isOnline)
            _buildOfflineView()
          else
            _buildPerformanceView(),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    ),
  );
  }

  Widget _buildDriverHeader() {
    return StreamBuilder<AppUser?>(
      stream: AuthService().getUserStream(widget.uid),
      builder: (context, userSnap) {
        final user = userSnap.data;
        return SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          elevation: 0,
          backgroundColor: AshallTheme.primaryColor,
          actions: [
            IconButton(
              tooltip: "الدعم الفني",
              icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupportChatScreen(userId: widget.uid))),
            ),
            IconButton(
              tooltip: "المحفظة والأرباح",
              icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletScreen(userId: widget.uid, isWithdrawMode: true))),
            ),
            IconButton(
              tooltip: "تسجيل الخروج",
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () => _handleLogout(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AshallTheme.primaryColor, Color(0xFF001A33)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(right: -40, top: -40, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.05))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 60, 25, 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25, 
                                  backgroundColor: Colors.white12, 
                                  backgroundImage: (user?.profileImage != null && user!.profileImage!.isNotEmpty) ? NetworkImage(user.profileImage!) : null,
                                  child: (user?.profileImage == null || user!.profileImage!.isEmpty) ? const Icon(Icons.person_rounded, color: Colors.white) : null
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user?.name ?? "كابتن...", style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text("${user?.rating ?? 5.0} (كابتن عام)", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            _buildStatusToggle(user?.isOnline ?? false),
                          ],
                        ),
                        const Spacer(),
                        StreamBuilder<List<AppOrder>>(
                          stream: _db.getDriverOrders(widget.uid),
                          builder: (context, ordersSnap) {
                            final orders = ordersSnap.data ?? [];
                            final today = DateTime.now();
                            final deliveredToday = orders.where((o) => 
                              o.status == OrderStatus.delivered && 
                              o.timestamp.day == today.day && 
                              o.timestamp.month == today.month
                            ).toList();
                            
                            double earnings = deliveredToday.fold(0.0, (sum, o) => sum + o.deliveryFee); 
                            int workMinutes = deliveredToday.length * 20; // Simulated work time based on orders

                            return Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletScreen(userId: widget.uid, isWithdrawMode: true))),
                                    child: _buildSummaryItem("أرباح اليوم", earnings.toStringAsFixed(2), Provider.of<SystemSettingsProvider>(context).settings.currencySymbol, Icons.account_balance_wallet_rounded)
                                  )
                                ),
                                const SizedBox(width: 15),
                                Expanded(child: _buildSummaryItem("تقدير العمل", "${workMinutes ~/ 60}:${(workMinutes % 60).toString().padLeft(2, '0')}", "H:M", Icons.timer_rounded)),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSummaryItem(String label, String val, String unit, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AshallTheme.secondaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: AshallTheme.secondaryColor, size: 18)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(width: 2),
                  Text(unit, style: const TextStyle(color: Colors.white30, fontSize: 8)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: PremiumCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("إجمالي أرباحك الأسبوعية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("المجموع: 45,000 ريال", style: TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3000), FlSpot(1, 4500), FlSpot(2, 3800), 
                        FlSpot(3, 6200), FlSpot(4, 5500), FlSpot(5, 8000), FlSpot(6, 7500),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true, 
                        color: Colors.green.withValues(alpha: 0.1)
                      ),
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

  Widget _buildControlTabs() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Expanded(child: _tabItem("مجمع المهمات العام", 0)),
          Expanded(child: _tabItem("الأداء والأرباح", 1)),
        ],
      ),
    );
  }

  Widget _tabItem(String title, int idx) {
    bool isSelected = _activeTab == idx;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)] : [],
        ),
        child: Center(
          child: Text(title, style: TextStyle(color: isSelected ? AshallTheme.primaryColor : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildOfflineView() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Giant "GO" button like Uber
            GestureDetector(
              onTap: () async {
                setState(() => _isOnline = true);
                await _db.updateUserOnlineStatus(widget.uid, true);
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AshallTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(color: AshallTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 10),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("GO", style: TextStyle(color: Colors.white, fontSize: 55, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      Text("ابدأ العمل", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Text("أنت خارج الخدمة", style: AshallTheme.titleStyle.copyWith(fontSize: 24)),
            const SizedBox(height: 15),
            const Text("اضغط على الزر أعلاه للاتصال بالشبكة\nوالبدء في تلقي المهمات الحصرية", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceView() {
    return StreamBuilder<List<AppOrder>>(
      stream: _db.getDriverOrders(widget.uid),
      builder: (context, ordersSnap) {
        final orders = ordersSnap.data ?? [];
        final completedOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();
        
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildRealChart(completedOrders),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSecondaryStat("تقييمك", "4.9", Icons.stars, Colors.orange)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildSecondaryStat("رحلات منجزة", "${completedOrders.length}", Icons.local_shipping_rounded, Colors.blue)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildHistoryList(),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildRealChart(List<AppOrder> completedOrders) {
    // Group earnings by day of the week for the last 7 days
    final now = DateTime.now();
    final Map<int, double> dailyEarnings = {};
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dayKey = (day.weekday % 7);
      dailyEarnings[dayKey] = 0;
    }

    for (var o in completedOrders) {
      if (o.timestamp.isAfter(now.subtract(const Duration(days: 7)))) {
        final dayKey = (o.timestamp.weekday % 7);
        dailyEarnings[dayKey] = (dailyEarnings[dayKey] ?? 0) + o.deliveryFee;
      }
    }

    final days = ["S", "M", "T", "W", "T", "F", "S"];
    
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("نشاط الأرباح الأسبوعي (${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final dayIndex = (now.subtract(Duration(days: 6 - i)).weekday % 7);
              final earnings = dailyEarnings[dayIndex] ?? 0;
              final maxEarnings = dailyEarnings.values.fold(1.0, (m, v) => v > m ? v : m);
              final heightPercent = (earnings / maxEarnings * 100).clamp(10, 100).toDouble();
              
              return _chartBar(days[dayIndex], heightPercent, isHighlight: i == 6);
            }),
          ),
        ],
      ),
    );
  }


  Widget _chartBar(String label, double h, {bool isHighlight = false}) {
    return Column(
      children: [
        Container(
          width: 18, height: h,
          decoration: BoxDecoration(
            color: isHighlight ? AshallTheme.secondaryColor : AshallTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSecondaryStat(String label, String val, IconData icon, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("آخر المهمات المنجزة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        StreamBuilder<List<AppOrder>>(
          stream: _db.getDriverOrders(widget.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final orders = snapshot.data!.where((o) => o.status == OrderStatus.delivered).toList();
            if (orders.isEmpty) {
              return const Center(child: Text("لا توجد مهمات منجزة بعد", style: TextStyle(color: Colors.grey)));
            }
            return Column(
              children: orders.take(5).map((o) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.done_all_rounded, color: Colors.green, size: 20)),
                title: Text("تم التوصيل بنجاح - طلب #${o.id.substring(0,6)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text("المبلغ المحصل: ${o.totalPrice} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(fontSize: 12)),
                trailing: const Text("مكتمل", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)), // removed logic that expects fixed commission for now
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveOrdersSliver() {
    return StreamBuilder<List<AppOrder>>(
      stream: _db.getDriverOrders(widget.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        
        final activeOrders = snapshot.data!.where((o) => 
          o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled
        ).toList();

        if (activeOrders.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: AshallTheme.secondaryColor, size: 20),
                    const SizedBox(width: 10),
                    const Text("مهماتك الحالية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    if (activeOrders.length > 1)
                      TextButton.icon(
                        icon: const Icon(Icons.alt_route_rounded, size: 16, color: AshallTheme.primaryColor),
                        label: const Text("خريطة المسار الذكي", style: TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RouteOptimizerScreen(activeOrders: activeOrders)));
                        },
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: activeOrders.length,
                  itemBuilder: (context, i) {
                    final o = activeOrders[i];
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      child: Stack(
                        children: [
                          PremiumCard(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("طلب #${o.id.substring(0,6)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    PremiumBadge(text: "جاري التنفيذ", color: AshallTheme.secondaryColor),
                                  ],
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Colors.grey, size: 16),
                                    const SizedBox(width: 5),
                                    Text("الوجهة محددة", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: PremiumButton(
                                    text: "متابعة المهمة",
                                    icon: Icons.arrow_back_rounded,
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveDeliveryScreen(orderId: o.id))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Decorative indicator
                          Positioned(
                            top: 0, right: 0, bottom: 0,
                            child: Container(width: 4, decoration: const BoxDecoration(color: AshallTheme.secondaryColor, borderRadius: BorderRadius.horizontal(right: Radius.circular(20)))),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderStream() {
    return StreamBuilder<List<AppOrder>>(
      stream: _db.getAvailableOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        final orders = snapshot.data!;
        
        if (orders.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(80), 
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: AshallTheme.primaryColor),
                    SizedBox(height: 30),
                    Icon(Icons.radar_rounded, size: 100, color: Colors.grey),
                    SizedBox(height: 25),
                    Text("جاري البحث عن طلبات قريبة...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 10),
                    Text("سيتم تنبيهك فور توفر مهمة متوافقة\nتأكد من بقائك متصل لاستلام التنبيهات", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            )
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildOrderCard(orders[i]),
              childCount: orders.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(AppOrder o) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PremiumBadge(
                text: o.status == OrderStatus.ready ? "جاهز للاستلام" : o.status == OrderStatus.preparing ? "قيد التجهيز" : "طلب جديد", 
                color: o.status == OrderStatus.ready ? Colors.teal : AshallTheme.primaryColor
              ),
              Text("الآن", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("رقم الطلب", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text("#${o.id.substring(0,6)}", style: AshallTheme.titleStyle.copyWith(fontSize: 18)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${o.totalPrice} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.w900, color: AshallTheme.secondaryColor, fontSize: 24)),
                  const Text("إجمالي التحصيل", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
          _buildStepRow(Icons.radio_button_checked_rounded, "استلام الطلب", "من المتجر المعني", Colors.blue),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(width: 2, height: 20, color: Colors.grey[200]),
          ),
          _buildStepRow(Icons.location_on_rounded, "تسليم في الموقع المرفق", "وجهة العميل", Colors.red),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  text: "قبول المهمة",
                  onPressed: () async {
                    bool success = await _db.assignDriverToOrder(o.id, widget.uid);
                    if (!mounted) return;
                    if (success) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveDeliveryScreen(orderId: o.id)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("عذراً، قام مندوب آخر بتولي هذا الطلب بالفعل"),
                        backgroundColor: Colors.orange,
                      ));
                    }
                  },
                ),
              ),
              const SizedBox(width: 15),
              _circleActionButton(Icons.map_rounded, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String label, String sub, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _circleActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: Colors.black54),
      ),
    );
  }

  Widget _buildStatusToggle(bool currentOnline) {
    if (!_initializedStatus) {
      _isOnline = currentOnline;
      _initializedStatus = true;
    }
    return GestureDetector(
      onTap: () async {
        setState(() => _isOnline = !_isOnline);
        await _db.updateUserOnlineStatus(widget.uid, _isOnline);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isOnline ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isOnline ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle, boxShadow: _isOnline ? [const BoxShadow(color: Colors.green, blurRadius: 5)] : [])),
            const SizedBox(width: 8),
            Text(_isOnline ? "متصل بالشبكة" : "غير متصل", style: TextStyle(color: _isOnline ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
