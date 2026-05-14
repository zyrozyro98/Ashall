import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../providers/system_settings_provider.dart';
import '../../models/order.dart';
import '../../models/app_user.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import '../../services/database_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _rtdbDriverPos;
  BitmapDescriptor? _motorcycleIcon;

  @override
  void initState() {
    super.initState();
    _createMotorcycleMarker();
    _listenToLiveLocation();
  }

  Future<void> _createMotorcycleMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120.0;

    final Paint shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(const Offset(size / 2, size / 2 + 5), size / 2.5, shadowPaint);

    final Paint paintOuter = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paintOuter);
    
    final Paint paintInner = Paint()..color = AshallTheme.primaryColor;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.4, paintInner);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.moped_rounded.codePoint),
      style: TextStyle(
        fontSize: size * 0.55,
        fontFamily: Icons.moped_rounded.fontFamily,
        package: Icons.moped_rounded.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size / 2 - textPainter.width / 2, size / 2 - textPainter.height / 2));

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      setState(() {
        _motorcycleIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      });
    }
  }

  void _listenToLiveLocation() {
    DatabaseService().getLiveLocationStream(widget.orderId).listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        if (mounted) {
          setState(() => _rtdbDriverPos = LatLng(lat, lng));
          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopOverlay(),
          _buildTrackingPanel(),
        ],
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 50, left: 20, right: 20,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Text("طلبك مؤمن ومحمي", style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final order = AppOrder.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        
        Set<Marker> markers = {};
        if (order.merchantLoc != null) {
          markers.add(Marker(
            markerId: const MarkerId("merchant"),
            position: LatLng(order.merchantLoc!.latitude, order.merchantLoc!.longitude),
            infoWindow: const InfoWindow(title: "المتجر"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ));
        }
        if (order.customerLoc != null) {
          markers.add(Marker(
            markerId: const MarkerId("customer"),
            position: LatLng(order.customerLoc!.latitude, order.customerLoc!.longitude),
            infoWindow: const InfoWindow(title: "موقع التسليم"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
        }
        if (_rtdbDriverPos != null) {
          markers.add(Marker(
            markerId: const MarkerId("driver"),
            position: _rtdbDriverPos!,
            icon: _motorcycleIcon ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 0.5),
            zIndex: 5,
          ));
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(target: _rtdbDriverPos ?? const LatLng(25.2048, 55.2708), zoom: 15),
          onMapCreated: (c) => _mapController = c,
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          padding: const EdgeInsets.only(bottom: 300),
        );
      },
    );
  }

  Widget _buildTrackingPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final order = AppOrder.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
              
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(25),
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 25),
                  
                  Row(
                    children: [
                      _buildStatusIcon(order.status),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getArabicStatus(order.status), style: AshallTheme.titleStyle.copyWith(fontSize: 22)),
                            Text("رقم الطلب: #${widget.orderId.substring(0, 8)}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      PremiumBadge(text: "${order.totalPrice} ريال", color: AshallTheme.secondaryColor),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),
                  
                  _buildTimelineStep(
                    "تم استلام الطلب", "نحن الآن نرسل طلبك للمتجر لبدء التحضير",
                    isDone: true, isFirst: true
                  ),
                  _buildTimelineStep(
                    "قيد التحضير", "المتجر يقوم حالياً بتجهيز طلبك بكل حب",
                    isDone: order.status.index >= OrderStatus.preparing.index,
                    isActive: order.status == OrderStatus.preparing
                  ),
                  _buildTimelineStep(
                    "بانتظار المندوب", "تم تجهيز الطلب وهو بانتظار استلامه من المندوب",
                    isDone: order.status.index >= OrderStatus.ready.index,
                    isActive: order.status == OrderStatus.ready
                  ),
                  _buildTimelineStep(
                    "الطريق إليك", "المندوب استلم طلبك وهو الآن في الطريق لمنزلك",
                    isDone: order.status.index >= OrderStatus.pickedUp.index,
                    isActive: order.status == OrderStatus.pickedUp
                  ),
                  _buildTimelineStep(
                    "تم التوصيل", "نتمنى أن تنال تجربتنا إعجابك!",
                    isDone: order.status == OrderStatus.delivered,
                    isActive: order.status == OrderStatus.delivered,
                    isLast: true
                  ),
                  
                  const SizedBox(height: 30),
                  if (order.driverId != null && order.driverId!.isNotEmpty)
                    _buildDriverContact(order.driverId!),
                  
                  const SizedBox(height: 100),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(OrderStatus status) {
    IconData icon;
    Color color;
    switch(status) {
      case OrderStatus.pending: icon = Icons.receipt_long_rounded; color = Colors.orange; break;
      case OrderStatus.preparing: icon = Icons.outdoor_grill_rounded; color = Colors.teal; break;
      case OrderStatus.ready: icon = Icons.inventory_2_rounded; color = Colors.blue; break;
      case OrderStatus.pickedUp: icon = Icons.moped_rounded; color = AshallTheme.primaryColor; break;
      case OrderStatus.delivered: icon = Icons.verified_rounded; color = Colors.green; break;
      case OrderStatus.cancelled: icon = Icons.cancel_rounded; color = Colors.red; break;
    }
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, {bool isDone = false, bool isActive = false, bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: isDone ? Colors.green : (isActive ? AshallTheme.primaryColor : Colors.grey[200]),
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: AshallTheme.primaryColor.withValues(alpha: 0.3), width: 5) : null,
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
            ),
            if (!isLast)
              Container(width: 2, height: 45, color: isDone ? Colors.green : Colors.grey[200]),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDone || isActive ? Colors.black : Colors.grey)),
              const SizedBox(height: 5),
              Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverContact(String driverId) {
    return FutureBuilder<AppUser?>(
      future: DatabaseService().getUserProfile(driverId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final driver = snap.data!;
        return PremiumCard(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              PremiumAvatar(name: driver.name, size: 50, isOnline: true),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("مندوب التوصيل", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_rounded, color: Colors.green),
                onPressed: () => launchUrl(Uri.parse("tel:${driver.phone}")),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getArabicStatus(OrderStatus s) {
    switch(s) {
      case OrderStatus.pending: return "بانتظار التأكيد";
      case OrderStatus.preparing: return "قيد التحضير";
      case OrderStatus.ready: return "جاهز للاستلام";
      case OrderStatus.pickedUp: return "الطريق إليك";
      case OrderStatus.delivered: return "تم التوصيل بنجاح";
      case OrderStatus.cancelled: return "تم إلغاء الطلب";
    }
  }
}
