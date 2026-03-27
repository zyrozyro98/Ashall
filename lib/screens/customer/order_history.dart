import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import 'order_tracking.dart';

class OrderHistoryScreen extends StatelessWidget {
  final String userId;
  OrderHistoryScreen({super.key, required this.userId});

  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
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
                elevation: 5,
                child: ListTile(
                  title: Text("طلب رقم: ${o.id.substring(0,8)}"),
                  subtitle: Text("الحالة: ${o.status.name} | ${o.totalPrice} AED"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
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
