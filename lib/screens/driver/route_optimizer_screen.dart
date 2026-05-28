import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

import '../../models/order.dart';
import '../../services/location_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

enum StopType { pickup, dropoff }

class RouteStop {
  final AppOrder order;
  final StopType type;
  final LatLng location;
  
  RouteStop({required this.order, required this.type, required this.location});
}

class RouteOptimizerScreen extends StatefulWidget {
  final List<AppOrder> activeOrders;
  const RouteOptimizerScreen({super.key, required this.activeOrders});

  @override
  State<RouteOptimizerScreen> createState() => _RouteOptimizerScreenState();
}

class _RouteOptimizerScreenState extends State<RouteOptimizerScreen> {
  final LocationService _locService = LocationService();
  GoogleMapController? _mapController;
  LatLng _currentPos = const LatLng(25.2048, 55.2708);
  bool _isLoading = true;
  List<RouteStop> _optimizedRoute = [];

  @override
  void initState() {
    super.initState();
    _calculateOptimalRoute();
  }

  // Calculate distance using Haversine formula
  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p)/2 + 
            c(p1.latitude * p) * c(p2.latitude * p) * 
            (1 - c((p2.longitude - p1.longitude) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<void> _calculateOptimalRoute() async {
    bool hasPerm = await _locService.checkPermissions();
    if (hasPerm) {
      final loc = await _locService.getCurrentLocation();
      if (loc != null) {
        _currentPos = LatLng(loc.latitude, loc.longitude);
      }
    }

    // Prepare initial available nodes
    List<RouteStop> availableNodes = [];
    for (var o in widget.activeOrders) {
      if (o.status == OrderStatus.pending || o.status == OrderStatus.preparing || o.status == OrderStatus.ready) {
        if (o.merchantLoc != null) {
          availableNodes.add(RouteStop(order: o, type: StopType.pickup, location: LatLng(o.merchantLoc!.latitude, o.merchantLoc!.longitude)));
        }
      } else if (o.status == OrderStatus.pickedUp) {
        if (o.customerLoc != null) {
          availableNodes.add(RouteStop(order: o, type: StopType.dropoff, location: LatLng(o.customerLoc!.latitude, o.customerLoc!.longitude)));
        }
      }
    }

    List<RouteStop> route = [];
    LatLng currentLoc = _currentPos;

    // Greedy nearest-neighbor with precedence constraints
    while (availableNodes.isNotEmpty) {
      // Find nearest node
      int nearestIndex = 0;
      double minDistance = double.infinity;
      for (int i = 0; i < availableNodes.length; i++) {
        double d = _calculateDistance(currentLoc, availableNodes[i].location);
        if (d < minDistance) {
          minDistance = d;
          nearestIndex = i;
        }
      }

      RouteStop nextStop = availableNodes[nearestIndex];
      route.add(nextStop);
      availableNodes.removeAt(nearestIndex);
      currentLoc = nextStop.location;

      // If it was a pickup, the dropoff is now available
      if (nextStop.type == StopType.pickup) {
        if (nextStop.order.customerLoc != null) {
          availableNodes.add(RouteStop(
            order: nextStop.order, 
            type: StopType.dropoff, 
            location: LatLng(nextStop.order.customerLoc!.latitude, nextStop.order.customerLoc!.longitude)
          ));
        }
      }
    }

    if (mounted) {
      setState(() {
        _optimizedRoute = route;
        _isLoading = false;
      });
      _fitMapToRoute();
    }
  }

  void _fitMapToRoute() {
    if (_mapController == null || _optimizedRoute.isEmpty) return;

    double minLat = _currentPos.latitude;
    double maxLat = _currentPos.latitude;
    double minLng = _currentPos.longitude;
    double maxLng = _currentPos.longitude;

    for (var stop in _optimizedRoute) {
      if (stop.location.latitude < minLat) minLat = stop.location.latitude;
      if (stop.location.latitude > maxLat) maxLat = stop.location.latitude;
      if (stop.location.longitude < minLng) minLng = stop.location.longitude;
      if (stop.location.longitude > maxLng) maxLng = stop.location.longitude;
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50.0 // padding
    ));
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("driver_current"), 
        position: _currentPos, 
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: "موقعك الحالي")
      )
    };

    for (int i = 0; i < _optimizedRoute.length; i++) {
      final stop = _optimizedRoute[i];
      markers.add(Marker(
        markerId: MarkerId("stop_\${i}"),
        position: stop.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(stop.type == StopType.pickup ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: stop.type == StopType.pickup ? "استلام طلب #\${stop.order.id.substring(0,6)}" : "تسليم طلب #\${stop.order.id.substring(0,6)}",
          snippet: "الخطوة \${i + 1}"
        )
      ));
    }

    // Draw polylines
    List<LatLng> polylinePoints = [_currentPos];
    polylinePoints.addAll(_optimizedRoute.map((s) => s.location));
    
    Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId("route"),
        points: polylinePoints,
        color: AshallTheme.primaryColor,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      )
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("المسار الذكي", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _currentPos, zoom: 14),
                onMapCreated: (c) {
                  _mapController = c;
                  Future.delayed(const Duration(milliseconds: 500), _fitMapToRoute);
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: markers,
                polylines: polylines,
              ),
              _buildRouteListPanel(),
            ],
          ),
    );
  }

  Widget _buildRouteListPanel() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 2)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              Text("المسار المقترح (\${_optimizedRoute.length} نقاط توقف)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              const Divider(),
              Expanded(
                child: _optimizedRoute.isEmpty
                  ? const Center(child: Text("لا توجد مهام نشطة حالياً", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _optimizedRoute.length,
                      itemBuilder: (context, i) {
                        final stop = _optimizedRoute[i];
                        bool isPickup = stop.type == StopType.pickup;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 35, height: 35,
                                    decoration: BoxDecoration(color: isPickup ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: Center(child: Text("\${i+1}", style: TextStyle(color: isPickup ? Colors.orange : Colors.red, fontWeight: FontWeight.bold))),
                                  ),
                                  if (i < _optimizedRoute.length - 1)
                                    Container(width: 2, height: 30, color: Colors.grey[300]),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: PremiumCard(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(isPickup ? "استلام من المتجر" : "تسليم للعميل", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          PremiumBadge(text: "طلب #\${stop.order.id.substring(0,4)}", color: Colors.grey),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(isPickup ? Icons.storefront_rounded : Icons.person_rounded, size: 14, color: Colors.grey),
                                          const SizedBox(width: 5),
                                          Text(isPickup ? "الذهاب لتجهيز/استلام الطلب" : "الذهاب لتسليم الطلب وإكمال العملية", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
