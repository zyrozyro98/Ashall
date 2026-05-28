import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math' show cos, sqrt, asin;

import '../../models/order.dart';
import '../../providers/system_settings_provider.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import 'active_delivery.dart';

class AvailableOrdersMapScreen extends StatefulWidget {
  final String uid;
  const AvailableOrdersMapScreen({super.key, required this.uid});

  @override
  State<AvailableOrdersMapScreen> createState() => _AvailableOrdersMapScreenState();
}

class _AvailableOrdersMapScreenState extends State<AvailableOrdersMapScreen> {
  final DatabaseService _db = DatabaseService();
  final LocationService _locService = LocationService();
  GoogleMapController? _mapController;
  

  LatLng _currentPos = const LatLng(25.2048, 55.2708);
  bool _isLoadingLoc = true;
  AppOrder? _selectedOrder;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool hasPerm = await _locService.checkPermissions().timeout(const Duration(seconds: 5));
      if (hasPerm) {
        // Adding timeout to avoid infinite loading indicator
        final loc = await _locService.getCurrentLocation().timeout(const Duration(seconds: 10), onTimeout: () => null);
        if (loc != null) {
          if (mounted) {
            setState(() {
              _currentPos = LatLng(loc.latitude, loc.longitude);
              _isLoadingLoc = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingLoc = false);
        }
        
        // Start streaming driver location
        _locService.streamLocationUpdates().listen((loc) {
          if (loc.latitude != null && loc.longitude != null && mounted) {
            setState(() {
              _currentPos = LatLng(loc.latitude!, loc.longitude!);
            });
          }
        });
      } else {
        if (mounted) setState(() => _isLoadingLoc = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLoc = false);
      debugPrint("Location initialization error: $e");
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p)/2 + 
            c(p1.latitude * p) * c(p2.latitude * p) * 
            (1 - c((p2.longitude - p1.longitude) * p))/2;
    return 12742 * asin(sqrt(a)); // returns distance in km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("خريطة رادار الطلبات", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<AppOrder>>(
        stream: _db.getAvailableOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text("خطأ في الاتصال بقاعدة البيانات", style: AshallTheme.titleStyle),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  PremiumButton(text: "تحديث", onPressed: () => setState(() {}), secondary: true),
                ],
              ),
            );
          }

          if (_isLoadingLoc) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text("جاري تحديد موقعك الجغرافي...", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _isLoadingLoc = false), 
                    child: const Text("تجاوز تحديد الموقع", style: TextStyle(color: AshallTheme.primaryColor))
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          Set<Marker> markers = {
            Marker(
              markerId: const MarkerId("driver"),
              position: _currentPos,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: "موقعك الحالي"),
              zIndexInt: 2,
            )
          };

          for (var o in orders) {
            if (o.merchantLoc != null) {
              final loc = LatLng(o.merchantLoc!.latitude, o.merchantLoc!.longitude);
              final dist = _calculateDistance(_currentPos, loc);
              
              markers.add(Marker(
                markerId: MarkerId(o.id),
                position: loc,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                infoWindow: InfoWindow(
                  title: "طلب #${o.id.substring(0,6)}",
                  snippet: "المسافة: ${dist.toStringAsFixed(1)} كم",
                ),
                onTap: () {
                  setState(() => _selectedOrder = o);
                  _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 15));
                },
                zIndexInt: 1,
              ));
            }
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _currentPos, zoom: 13),
                onMapCreated: (c) => _mapController = c,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: markers,
                onTap: (_) => setState(() => _selectedOrder = null),
              ),

              // Floating indicator
              Positioned(
                top: 20, left: 20, right: 20,
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: Colors.green, size: 24),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("جاري البحث في الرادار", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text("يوجد ${orders.length} طلبات متاحة حولك", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedOrder != null)
                Positioned(
                  bottom: 30, left: 20, right: 20,
                  child: _buildOrderCard(_selectedOrder!),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(AppOrder o) {
    double dist = 0;
    if (o.merchantLoc != null) {
      dist = _calculateDistance(_currentPos, LatLng(o.merchantLoc!.latitude, o.merchantLoc!.longitude));
    }

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PremiumBadge(
                text: o.status == OrderStatus.ready ? "جاهز للاستلام" : "طلب جديد", 
                color: o.status == OrderStatus.ready ? Colors.teal : AshallTheme.primaryColor
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car_rounded, size: 14, color: Colors.orange),
                    const SizedBox(width: 5),
                    Text("${dist.toStringAsFixed(1)} كم", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("رقم الطلب", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text("#${o.id.substring(0,6)}", style: AshallTheme.titleStyle.copyWith(fontSize: 18)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${o.totalPrice} ${Provider.of<SystemSettingsProvider>(context, listen: false).settings.currencySymbol}", style: const TextStyle(fontWeight: FontWeight.w900, color: AshallTheme.secondaryColor, fontSize: 24)),
                  const Text("إجمالي التحصيل", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: PremiumButton(
              text: "قبول المهمة والتوجه",
              icon: Icons.check_circle_outline_rounded,
              onPressed: () async {
                bool success = await _db.assignDriverToOrder(o.id, widget.uid);
                if (!mounted) return;
                if (success) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActiveDeliveryScreen(orderId: o.id)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("عذراً، قام مندوب آخر بتولي هذا الطلب بالفعل"),
                    backgroundColor: Colors.orange,
                  ));
                  setState(() => _selectedOrder = null);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
