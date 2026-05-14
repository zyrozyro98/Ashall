import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../providers/system_settings_provider.dart';
import '../../../utils/style_constants.dart';
import '../../../widgets/premium_ui.dart';

class AdminStatsModule extends StatelessWidget {
  const AdminStatsModule({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("لوحة المؤشرات العامة", style: AshallTheme.titleStyle.copyWith(fontSize: 26)),
              const Icon(Icons.analytics_outlined, color: AshallTheme.primaryColor, size: 30),
            ],
          ),
          const SizedBox(height: 10),
          Text("متابعة أداء النظام والنمو في الوقت الفعلي", style: AshallTheme.subtitleStyle),
          const SizedBox(height: 30),
          
          // Main Analytics Wall
          _buildRevenueAnalytics(context),
          const SizedBox(height: 30),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                PremiumQuickAction(label: "إضافة منتج", icon: Icons.add_business_rounded, color: Colors.blue, onTap: () {}),
                const SizedBox(width: 20),
                PremiumQuickAction(label: "إرسال تنبيه", icon: Icons.notifications_active_rounded, color: Colors.orange, onTap: () {}),
                const SizedBox(width: 20),
                PremiumQuickAction(label: "تصدير تقرير", icon: Icons.file_download_rounded, color: Colors.teal, onTap: () {}),
                const SizedBox(width: 20),
                PremiumQuickAction(label: "المساعدة", icon: Icons.support_agent_rounded, color: Colors.purple, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          const PremiumSectionTitle(title: "نظرة سريعة على النمو", icon: Icons.speed_rounded),
          const SizedBox(height: 10),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _buildMetricCard("العملاء", "users", Icons.people_rounded, Colors.blue),
              _buildMetricCard("التجار", "merchants", Icons.store_mall_directory_rounded, Colors.orange),
              _buildMetricCard("السائقين", "drivers", Icons.delivery_dining_rounded, Colors.green),
              _buildDelayedMetricCard(context),
            ],
          ),
          
          const SizedBox(height: 30),
          const PremiumSectionTitle(title: "توزيع الأدوار في النظام", icon: Icons.pie_chart_rounded),
          const SizedBox(height: 10),
          _buildDistributionMap(),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalytics(BuildContext context) {
    return PremiumCard(
      color: AshallTheme.primaryColor,
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("إجمالي التداول", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("124,500 ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: GoogleFonts.cairo(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.show_chart, color: AshallTheme.secondaryColor, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 3), FlSpot(2, 4), FlSpot(4, 3.5), FlSpot(6, 6), FlSpot(8, 4), FlSpot(10, 7)],
                    isCurved: true,
                    color: AshallTheme.secondaryColor,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AshallTheme.secondaryColor.withValues(alpha: 0.4), AshallTheme.secondaryColor.withValues(alpha: 0)],
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

  Widget _buildMetricCard(String label, String id, IconData icon, Color color) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance.collection(id).count().get(),
      builder: (context, snap) {
        String count = snap.hasData ? snap.data!.count.toString() : "0";
        return PremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(count, style: AshallTheme.titleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w900)),
              Text(label, style: AshallTheme.subtitleStyle.copyWith(fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDelayedMetricCard(BuildContext context) {
    final settings = Provider.of<SystemSettingsProvider>(context, listen: false).settings;
    final timeout = settings.orderConfirmationTimeoutMinutes;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders')
          .where('status', isEqualTo: 0) // OrderStatus.pending
          .snapshots(),
      builder: (context, snap) {
        int overdueCount = 0;
        if (snap.hasData) {
          final now = DateTime.now();
          for (var doc in snap.data!.docs) {
            final ts = (doc.data() as Map<String, dynamic>)['timestamp'];
            if (ts is Timestamp) {
               if (now.difference(ts.toDate()).inMinutes >= timeout) {
                 overdueCount++;
               }
            }
          }
        }
        
        return PremiumCard(
          padding: const EdgeInsets.all(20),
          color: overdueCount > 0 ? Colors.red.withValues(alpha: 0.05) : Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (overdueCount > 0 ? Colors.red : Colors.grey).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.timer_off_rounded, color: overdueCount > 0 ? Colors.red : Colors.grey, size: 28),
              ),
              const SizedBox(height: 12),
              Text(overdueCount.toString(), style: AshallTheme.titleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w900, color: overdueCount > 0 ? Colors.red : null)),
              Text("طلبات متأخرة", style: AshallTheme.subtitleStyle.copyWith(fontSize: 14, color: overdueCount > 0 ? Colors.red : null)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDistributionMap() {
    return PremiumCard(
      padding: const EdgeInsets.all(25),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 5,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(value: 40, color: Colors.blue, title: '', radius: 25),
                    PieChartSectionData(value: 20, color: Colors.orange, title: '', radius: 25),
                    PieChartSectionData(value: 15, color: Colors.green, title: '', radius: 25),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            flex: 3,
            child: Column(
              children: [
                _Legend(color: Colors.blue, label: "العملاء (40%)"),
                SizedBox(height: 10),
                _Legend(color: Colors.orange, label: "التجار (20%)"),
                SizedBox(height: 10),
                _Legend(color: Colors.green, label: "السائقين (15%)"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: AshallTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
