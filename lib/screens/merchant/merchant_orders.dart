import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/system_settings_provider.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';

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
          itemBuilder: (context, i) => _AnimatedOrderCard(
            order: orders[i],
            onAccept: () {
              HapticFeedback.heavyImpact();
              _db.updateOrderStatus(orders[i].id, OrderStatus.preparing);
            },
            onReady: () {
              HapticFeedback.mediumImpact();
              _db.updateOrderStatus(orders[i].id, OrderStatus.ready);
            },
            onCancel: () => _showCancelDialog(orders[i].id),
          ),
        );
      },
    );
  }

  void _showCancelDialog(String orderId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text("إلغاء الطلب", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ لا يمكن التراجع وسيتم إخطار العميل فوراً."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("تراجع", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text("لا توجد طلبات هنا حالياً", style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("عندما تتلقى طلبات جديدة ستظهر في هذه القائمة", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
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
            Text("فشل الاتصال", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedOrderCard extends StatefulWidget {
  final AppOrder order;
  final VoidCallback onAccept;
  final VoidCallback onReady;
  final VoidCallback onCancel;

  const _AnimatedOrderCard({
    required this.order,
    required this.onAccept,
    required this.onReady,
    required this.onCancel,
  });

  @override
  State<_AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<_AnimatedOrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPending = widget.order.status == OrderStatus.pending;
    bool isPreparing = widget.order.status == OrderStatus.preparing;
    
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: isPending ? Colors.orange.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: isPending ? 25 : 15,
            offset: const Offset(0, 8),
          )
        ],
        border: isPending ? Border.all(color: Colors.orange.withValues(alpha: 0.6), width: 2) : Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPending 
                    ? [Colors.orange.shade500, Colors.orange.shade400]
                    : isPreparing 
                      ? [Colors.blue.shade600, Colors.blue.shade400]
                      : [Colors.grey.shade200, Colors.grey.shade100],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                        child: Icon(isPending ? Icons.local_fire_department_rounded : isPreparing ? Icons.restaurant_rounded : Icons.check_circle_rounded, color: isPending || isPreparing ? Colors.white : Colors.grey.shade600, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("الطلب #${widget.order.id.substring(0, 6).toUpperCase()}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isPending || isPreparing ? Colors.white : Colors.black87)),
                          Text("منذ ${DateTime.now().difference(widget.order.timestamp).inMinutes} دقيقة • ${widget.order.items.length} منتجات", style: TextStyle(color: isPending || isPreparing ? Colors.white70 : Colors.grey.shade700, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5)]),
                    child: Text(
                      isPending ? "جديد عاجل" : isPreparing ? "جاري التجهيز" : "مكتمل",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isPending ? Colors.orange.shade700 : isPreparing ? Colors.blue.shade700 : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
            
            // Order Items List
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: widget.order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]
                        ),
                        child: Text("${item.quantity}x", style: const TextStyle(color: AshallTheme.primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ),
                      Text((item.price * item.quantity).toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey.shade800)),
                    ],
                  ),
                )).toList(),
              ),
            ),

            // Driver Info (if preparing and driver assigned)
            if (isPreparing && widget.order.driverId != null && widget.order.driverId!.isNotEmpty) 
              StreamBuilder<DocumentSnapshot>(
                stream: DatabaseService().getUserStream(widget.order.driverId!),
                builder: (context, dSnap) {
                  String dName = "جاري تعيين مندوب...";
                  String dPhone = "";
                  if (dSnap.hasData && dSnap.data!.exists) {
                    final d = dSnap.data!.data() as Map<String, dynamic>;
                    dName = d['name'] ?? 'كابتن أسهل';
                    dPhone = d['phone'] ?? '';
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, border: Border(top: BorderSide(color: Colors.blue.shade100), bottom: BorderSide(color: Colors.blue.shade100))),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.two_wheeler_rounded, color: Colors.blue.shade600, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("المندوب المستلم", style: TextStyle(color: Colors.blue.shade400, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(dName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blue.shade900)),
                        ])),
                        if (dPhone.isNotEmpty) 
                          IconButton(
                            icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle), child: const Icon(Icons.call_rounded, color: Colors.green, size: 20)), 
                            onPressed: () => launchUrl(Uri.parse("tel:$dPhone"))
                          ),
                      ],
                    ),
                  );
                },
              ),

            // Footer & Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("إجمالي التحصيل", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("${widget.order.totalPrice.toStringAsFixed(2)} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.w900, color: AshallTheme.secondaryColor, fontSize: 22)),
                    ],
                  ),
                  const Spacer(),
                  if (isPending) ...[
                    InkWell(
                      onTap: widget.onCancel,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
                        child: Icon(Icons.close_rounded, color: Colors.red.shade600),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: widget.onAccept,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.outdoor_grill_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text("قبول والبدء", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else if (isPreparing) ...[
                    Expanded(
                      child: InkWell(
                        onTap: widget.onReady,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AshallTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: AshallTheme.secondaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.room_service_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text("الطلب جاهز للتسليم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                     Text(widget.order.timestamp.toString().substring(11, 16), style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return isPending
        ? ScaleTransition(scale: _pulseAnimation, child: card)
        : card;
  }
}

