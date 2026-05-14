import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class MerchantSettingsScreen extends StatefulWidget {
  final AppUser user;
  const MerchantSettingsScreen({super.key, required this.user});

  @override
  State<MerchantSettingsScreen> createState() => _MerchantSettingsScreenState();
}

class _MerchantSettingsScreenState extends State<MerchantSettingsScreen> {
  final _db = DatabaseService();
  final _loc = LocationService();
  
  late TextEditingController _nameC;
  late TextEditingController _addrC;
  late TextEditingController _hoursC;
  GeoPoint? _currentLocation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.user.storeName ?? widget.user.name);
    _addrC = TextEditingController(text: widget.user.storeAddress);
    _hoursC = TextEditingController(text: widget.user.workingHours);
    _currentLocation = widget.user.storeLocation;
  }

  Future<void> _updateLocation() async {
    bool hasPerm = await _loc.checkPermissions();
    if (!hasPerm) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى تفعيل صلاحيات الموقع")));
      return;
    }
    
    try {
      final pos = await _loc.streamLocationUpdates().first;
      if (pos.latitude != null && pos.longitude != null) {
        setState(() => _currentLocation = GeoPoint(pos.latitude!, pos.longitude!));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديد موقع المتجر بنجاح")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل تحديد الموقع: $e")));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _db.updateMerchantSettings(widget.user.uid, {
        'storeName': _nameC.text.trim(),
        'storeAddress': _addrC.text.trim(),
        'workingHours': _hoursC.text.trim(),
        'storeLocation': _currentLocation,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ إعدادات المتجر بنجاح")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ أثناء الحفظ: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إعدادات المتجر"), backgroundColor: AshallTheme.primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            PremiumTextField(
              label: "اسم المتجر",
              controller: _nameC,
              icon: Icons.store_rounded,
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              label: "عنوان المتجر بالتفصيل",
              controller: _addrC,
              icon: Icons.location_city_rounded,
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              label: "أوقات الدوام (مثال: 8 ص - 10 م)",
              controller: _hoursC,
              icon: Icons.access_time_filled_rounded,
            ),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!)
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.map_rounded, color: AshallTheme.primaryColor),
                      SizedBox(width: 15),
                      Text("موقع المتجر على الخريطة", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _currentLocation != null 
                      ? "تم تحديد الإحداثيات: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}"
                      : "لم يتم تحديد الموقع بعد",
                    style: TextStyle(color: _currentLocation != null ? Colors.green : Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: _updateLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text("تحديث لموقعي الحالي"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AshallTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            _isSaving 
              ? const CircularProgressIndicator()
              : PremiumButton(
                  text: "حفظ الإعدادات",
                  icon: Icons.save_rounded,
                  onPressed: _save,
                ),
          ],
        ),
      ),
    );
  }
}
