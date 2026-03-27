import 'package:flutter/material.dart';
import 'active_delivery.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class DriverDashboard extends StatefulWidget {
  final String uid;
  const DriverDashboard({super.key, required this.uid});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("لوحة السائق", style: AshallTheme.titleStyle.copyWith(color: Colors.white)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<AppOrder>>(
        stream: _db.getAvailableOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("طلب رقم: ${o.id.substring(0,6)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("${o.totalPrice} AED", style: const TextStyle(fontWeight: FontWeight.bold, color: AshallTheme.primaryColor)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("عدد الأصناف: ${o.items.length}", style: AshallTheme.subtitleStyle.copyWith(fontSize: 14)),
                      const SizedBox(height: 20),
                      PremiumButton(
                        text: "قبول التوصيل",
                        onPressed: () async {
                          await _db.updateOrderStatus(o.id, OrderStatus.pickedUp, driverId: widget.uid);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveDeliveryScreen(orderId: o.id)));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
