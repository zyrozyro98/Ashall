import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/system_settings_provider.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class MerchantOrdersScreen extends StatefulWidget {
  final String merchantId;
  const MerchantOrdersScreen({super.key, required this.merchantId});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          title: Text("إدارة الطلبات المتقدمة", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          backgroundColor: AshallTheme.primaryColor,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AshallTheme.secondaryColor,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "طلبات جارية", icon: Icon(Icons.flash_on_rounded)),
              Tab(text: "قيد التجهيز", icon: Icon(Icons.restaurant_rounded)),
              Tab(text: "السجل والأرشيف", icon: Icon(Icons.history_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList([OrderStatus.pending, OrderStatus.ready, OrderStatus.pickedUp]),
            _buildOrderList([OrderStatus.preparing]),
            _buildOrderList([OrderStatus.delivered, OrderStatus.cancelled]),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderStatus> statuses) {
    return StreamBuilder<List<AppOrder>>(
      stream: _db.getMerchantOrders(widget.merchantId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allOrders = snapshot.data ?? [];
        final orders = allOrders.where((o) => statuses.contains(o.status)).toList();

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, i) => _buildEnhancedOrderCard(orders[i]),
        );
      },
    );
  }

  Widget _buildEnhancedOrderCard(AppOrder o) {
    bool isPending = o.status == OrderStatus.pending;
    bool isPreparing = o.status == OrderStatus.preparing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isPending ? AshallTheme.primaryColor.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05), 
              blurRadius: isPending ? 20 : 10, 
              offset: const Offset(0, 5)
            )
          ],
          border: isPending ? Border.all(color: AshallTheme.primaryColor.withValues(alpha: 0.5), width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Ticket
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isPending ? AshallTheme.primaryColor.withValues(alpha: 0.05) : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 5),
                          Text("الطلب #${o.id.substring(0, 6).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("منذ ${DateTime.now().difference(o.timestamp).inMinutes} دقيقة • ${o.items.length} عناصر", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  PremiumBadge(
                    text: _getStatusText(o.status), 
                    color: _getStatusColor(o.status)
                  ),
                ],
              ),
            ),
            
            // Divider (Dashed)
            Row(
              children: List.generate(30, (index) => Expanded(child: Container(height: 1, color: index % 2 == 0 ? Colors.transparent : Colors.grey[300]))),
            ),

            // Order Items
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: o.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28, height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AshallTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text("${item.quantity}x", style: const TextStyle(color: AshallTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      Text("${(item.price * item.quantity).toStringAsFixed(2)} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                )).toList(),
              ),
            ),

            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1)),

            // Driver Info
            if (o.driverId != null && o.driverId!.isNotEmpty) ...[
              StreamBuilder<DocumentSnapshot>(
                stream: _db.getUserStream(o.driverId!),
                builder: (context, dSnap) {
                  String dName = "جاري تعيين مندوب...";
                  String dPhone = "";
                  if (dSnap.hasData && dSnap.data!.exists) {
                    final d = dSnap.data!.data() as Map<String, dynamic>;
                    dName = d['name'] ?? 'كابتن أسهل';
                    dPhone = d['phone'] ?? '';
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.two_wheeler_rounded, color: Colors.blue, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("المندوب المستلم", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(dName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ])),
                        if (dPhone.isNotEmpty) 
                          IconButton(
                            icon: const Icon(Icons.call_rounded, color: Colors.green), 
                            onPressed: () => launchUrl(Uri.parse("tel:$dPhone"))
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
            
            // Footer & Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("إجمالي التحصيل", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text("${o.totalPrice.toStringAsFixed(2)} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.w900, color: AshallTheme.secondaryColor, fontSize: 22)),
                    ],
                  ),
                  if (isPending)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.red),
                          style: IconButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.1)),
                          onPressed: () => _showCancelDialog(o.id),
                        ),
                        const SizedBox(width: 10),
                        PremiumButton(
                          text: "قبول البدء 🍳", 
                          onPressed: () => _db.updateOrderStatus(o.id, OrderStatus.preparing),
                        ),
                      ],
                    )
                  else if (isPreparing)
                    PremiumButton(
                      text: "طلب جاهز للاستلام ✅", 
                      onPressed: () => _db.updateOrderStatus(o.id, OrderStatus.ready),
                    )
                  else
                    Text(o.timestamp.toString().substring(11, 16), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("إلغاء الطلب", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: const Text("هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("تراجع")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(c);
              _db.updateOrderStatus(orderId, OrderStatus.cancelled);
            },
            child: const Text("تأكيد الإلغاء", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text("لا توجد طلبات في هذا القسم", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text("فشل الاتصال بقاعدة البيانات", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return "جديد 🔥";
      case OrderStatus.preparing: return "قيد التحضير";
      case OrderStatus.ready: return "جاهز للاستلام";
      case OrderStatus.pickedUp: return "مع المندوب";
      case OrderStatus.delivered: return "مكتمل 👍";
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
}

