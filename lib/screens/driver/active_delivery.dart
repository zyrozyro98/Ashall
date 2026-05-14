import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/system_settings_provider.dart';
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
  final DatabaseService _db = DatabaseService();
  final LocationService _locService = LocationService();
  
  GoogleMapController? _mapController;
  bool _isStreaming = false;
  LatLng _currentPos = const LatLng(25.2048, 55.2708);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("مهمة نشطة #${widget.orderId.substring(0, 6)}", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<AppOrder>(
        stream: _db.getOrderStream(widget.orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final o = snapshot.data!;

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _currentPos, zoom: 15),
                onMapCreated: (c) => _mapController = c,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: {
                  Marker(markerId: const MarkerId("driver"), position: _currentPos, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
                  if (o.merchantLoc != null) Marker(markerId: const MarkerId("merchant"), position: LatLng(o.merchantLoc!.latitude, o.merchantLoc!.longitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)),
                  if (o.customerLoc != null) Marker(markerId: const MarkerId("customer"), position: LatLng(o.customerLoc!.latitude, o.customerLoc!.longitude)),
                },
              ),
              
              // Floating Header overlay
              Positioned(
                top: 20, left: 20, right: 20,
                child: GlassContainer(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AshallTheme.secondaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.delivery_dining_rounded, color: AshallTheme.secondaryColor)),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getStatusLabel(o.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text("قيمة التحصيل: ${o.totalPrice} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sheet Interaction
              _buildBottomPanel(context, o),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, AppOrder o) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 30, 25, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 25),
            
            StreamBuilder<DocumentSnapshot>(
              stream: _db.getUserStream(
                (o.status == OrderStatus.preparing || o.status == OrderStatus.ready || o.status == OrderStatus.pending) 
                  ? o.merchantId 
                  : o.customerId
              ),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
                final userData = userSnap.data!.data() as Map<String, dynamic>?;
                if (userData == null) return const SizedBox();

                bool isTargetMerchant = (o.status == OrderStatus.preparing || o.status == OrderStatus.ready || o.status == OrderStatus.pending);
                String targetName = userData['name'] ?? 'مستخدم غير معروف';
                if (isTargetMerchant && userData['storeName'] != null) {
                  targetName = userData['storeName'];
                }
                String targetPhone = userData['phone'] ?? '';
                String address = userData['storeAddress'] ?? '';
                String hours = userData['workingHours'] ?? '';
                GeoPoint? loc = userData['storeLocation'];
                
                return Column(
                  children: [
                    _buildTargetInfo(
                      isTargetMerchant ? "الاستلام من: $targetName" : "التسليم إلى: $targetName",
                      targetPhone
                    ),
                    if (isTargetMerchant && address.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(address, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                          if (loc != null) IconButton(
                             icon: const Icon(Icons.map_rounded, color: Colors.blue, size: 20),
                             onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}")),
                          ),
                        ],
                      ),
                    ],
                    if (isTargetMerchant && hours.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("أوقات الدوام: $hours", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Always show status info (Action Buttons/Containers)
            _buildActionButtons(context, o),
            
            // Show "Start Mission" button if tracking hasn't started and order is accepted by store
            if (o.status != OrderStatus.pending && !_isStreaming) ...[
              const SizedBox(height: 20),
              PremiumButton(
                text: "تفعيل التتبع وبدء المهمة", 
                icon: Icons.gps_fixed_rounded,
                onPressed: _startStreaming,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInfo(String title, String phone) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text("الوجهة الحالية", style: TextStyle(color: Colors.grey, fontSize: 12)),
               Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => launchUrl(Uri.parse("tel:$phone")),
          icon: const Icon(Icons.call_rounded, color: Colors.green),
          style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1), padding: const EdgeInsets.all(12)),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppOrder o) {
    if (o.status == OrderStatus.pending) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.orange))),
            SizedBox(width: 15),
            Expanded(child: Text("بانتظار قبول التاجر للطلب...", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }

    if (o.status == OrderStatus.preparing) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 15),
            Expanded(child: Text("المتجر يقوم بتجهيز طلبك حالياً...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }
    
    if (o.status == OrderStatus.ready) {
      return PremiumButton(
        text: "أنا في المتجر، استلمت الطلب", 
        icon: Icons.inventory_2_rounded,
        onPressed: () => _db.updateOrderStatus(o.id, OrderStatus.pickedUp),
      );
    }

    if (o.status == OrderStatus.pickedUp) {
      return PremiumButton(
        text: "تم التوصيل وتسليم الطلب", 
        icon: Icons.verified_rounded,
        onPressed: () => _showDeliveryConfirmation(context, o),
      );
    }

    return const SizedBox();
  }

  void _showDeliveryConfirmation(BuildContext context, AppOrder o) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("تأكيد التسليم", style: AshallTheme.titleStyle, textAlign: TextAlign.center),
        content: const Text("هل تأكدت من استلام المبلغ من العميل وتسليم كافة المنتجات؟", textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AshallTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              _db.updateOrderStatus(o.id, OrderStatus.delivered);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close screen
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إكمال العملية بنجاح!"), backgroundColor: Colors.green));
            },
            child: const Text("نعم، تم التسليم", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return "بانتظار قبول المتجر";
      case OrderStatus.preparing: return "جاري التجهيز بالمحل";
      case OrderStatus.ready: return "الطلب جاهز للاستلام";
      case OrderStatus.pickedUp: return "جاري التوصيل للعميل";
      default: return "مهمة نشطة";
    }
  }

  void _startStreaming() async {
    bool hasPermission = await _locService.checkPermissions();
    if (!mounted) return;
    if (hasPermission) {
      setState(() => _isStreaming = true);
      _locService.streamLocationUpdates().listen((loc) {
        if (loc.latitude != null && loc.longitude != null) {
          LatLng pin = LatLng(loc.latitude!, loc.longitude!);
          _db.updateDriverLocation(widget.orderId, GeoPoint(loc.latitude!, loc.longitude!));
          _mapController?.animateCamera(CameraUpdate.newLatLng(pin));
          if (mounted) setState(() => _currentPos = pin);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى تفعيل صلاحية الموقع لبدء التتبع")));
    }
  }
}
