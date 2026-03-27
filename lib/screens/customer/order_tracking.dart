import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order.dart';
import '../../utils/style_constants.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تتبع الطلب", style: AshallTheme.titleStyle.copyWith(color: Colors.white)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final order = AppOrder.fromMap(data, widget.orderId);
          final driverLoc = order.driverLoc;

          Set<Marker> markers = {};
          if (driverLoc != null) {
            markers.add(Marker(
              markerId: const MarkerId("driver"),
              position: LatLng(driverLoc.latitude, driverLoc.longitude),
              infoWindow: const InfoWindow(title: "موقع السائق"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ));
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(25.2048, 55.2708), zoom: 14),
                markers: markers,
                onMapCreated: (m) {},
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("حالة الطلب: ${order.status.name}", style: AshallTheme.titleStyle.copyWith(color: AshallTheme.primaryColor)),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("رقم الطلب: ${order.id.substring(0,8)}"),
                            Text("السعر: ${order.totalPrice} AED"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
