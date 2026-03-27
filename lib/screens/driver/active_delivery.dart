import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final String orderId;
  const ActiveDeliveryScreen({super.key, required this.orderId});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final LocationService _locService = LocationService();
  final DatabaseService _db = DatabaseService();
  bool _isStreaming = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("توصيل نشط"), backgroundColor: AshallTheme.primaryColor),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Icon(Icons.delivery_dining, size: 80, color: AshallTheme.primaryColor),
            const SizedBox(height: 20),
            Text("الطلب رقم: ${widget.orderId.substring(0,8)}", style: AshallTheme.titleStyle),
            const SizedBox(height: 40),
            
            PremiumButton(
              text: _isStreaming ? "تتبع الموقع مُفعل" : "بدء التوصيل وبث الموقع",
              icon: _isStreaming ? Icons.location_on : Icons.play_arrow,
              onPressed: _isStreaming ? () {} : _startStreaming,
            ),
            const SizedBox(height: 20),
            if (_isStreaming) PremiumButton(
              text: "تم التوصيل بنجاح",
              icon: Icons.check_circle,
              onPressed: () async {
                await _db.updateOrderStatus(widget.orderId, OrderStatus.delivered);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startStreaming() async {
    bool hasPermission = await _locService.checkPermissions();
    if (hasPermission) {
      setState(() => _isStreaming = true);
      _locService.streamLocationUpdates().listen((loc) {
        if (loc.latitude != null && loc.longitude != null) {
          _db.updateDriverLocation(widget.orderId, GeoPoint(loc.latitude!, loc.longitude!));
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى منح صلاحية الوصول للموقع")));
    }
  }
}
