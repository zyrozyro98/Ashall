import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../providers/system_settings_provider.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import 'order_tracking.dart';

class OrderHistoryScreen extends StatelessWidget {
  final String userId;
  OrderHistoryScreen({super.key, required this.userId});

  final DatabaseService _db = DatabaseService();

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

  double _getStatusProgress(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return 0.2;
      case OrderStatus.preparing: return 0.4;
      case OrderStatus.ready: return 0.6;
      case OrderStatus.pickedUp: return 0.8;
      case OrderStatus.delivered: return 1.0;
      case OrderStatus.cancelled: return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SystemSettingsProvider>(context).settings;
    return Scaffold(
      appBar: AppBar(title: const Text("طلباتي"), backgroundColor: AshallTheme.primaryColor),
      body: StreamBuilder<List<AppOrder>>(
        stream: _db.getCustomerOrders(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!;
          if (orders.isEmpty) return const Center(child: Text("لا توجد طلبات سابقة"));
          
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("طلب #${o.id.substring(0,8)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      PremiumBadge(text: _getArabicStatus(o.status), color: _getStatusColor(o.status)),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(o.items.map((i) => "${i.quantity}x ${i.name}").join(", "), overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 12),
                      
                      // Progress Indicator
                      if (o.status != OrderStatus.cancelled && o.status != OrderStatus.delivered) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: _getStatusProgress(o.status),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(o.status)),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      Text("إجمالي: ${o.totalPrice} ${settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.bold, color: AshallTheme.primaryColor)),
                    ],
                  ),
                  trailing: o.status != OrderStatus.cancelled ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
                  onTap: o.status == OrderStatus.cancelled ? null : () {
                    if (o.status == OrderStatus.delivered) {
                      _showRatingDialog(context, o.id);
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id)));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String orderId) {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تقييم الطلب"),
        content: StatefulBuilder(
          builder: (context, setState) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              icon: Icon(index < rating ? Icons.star : Icons.star_border, color: AshallTheme.secondaryColor),
              onPressed: () => setState(() => rating = index + 1),
            )),
          ),
        ),
        actions: [
          PremiumButton(
            text: "إرسال التقييم",
            onPressed: () {
              // Logic to update rating in Firestore (Optional: can create a ratings collection)
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("شكراً لتقييمك!")));
            },
          ),
        ],
      ),
    );
  }
}
