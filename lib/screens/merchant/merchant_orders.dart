import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../utils/style_constants.dart';

class MerchantOrdersScreen extends StatelessWidget {
  final String merchantId;
  MerchantOrdersScreen({super.key, required this.merchantId});

  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("طلبات المتجر"), backgroundColor: AshallTheme.primaryColor),
      body: StreamBuilder<List<AppOrder>>(
        stream: _db.getMerchantOrders(merchantId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snapshot.data!;
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("طلب رقم: ${o.id.substring(0,6)}"),
                  subtitle: Text("الحالة: ${o.status.name} | الإجمالي: ${o.totalPrice} AED"),
                  trailing: o.status == OrderStatus.pending ? TextButton(
                    onPressed: () => _db.updateOrderStatus(o.id, OrderStatus.pickedUp),
                    child: const Text("جاهز للاستلام"),
                  ) : Text(o.status.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
