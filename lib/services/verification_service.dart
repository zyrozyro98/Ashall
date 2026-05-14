import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math';
import 'dart:io';

class SmartVerificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Get unique device ID
  Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      var info = await _deviceInfo.androidInfo;
      return info.id; // Unique Android ID
    } else if (Platform.isIOS) {
      var info = await _deviceInfo.iosInfo;
      return info.identifierForVendor ?? "ios_unknown";
    }
    return "unknown_device";
  }

  // Generate a smart verification token
  String generateToken() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  // Option 1: WhatsApp Verification Bridge (100% Free)
  Future<void> startWhatsAppVerification({
    required String phone,
    required String token,
    required String adminPhone, 
  }) async {
    final message = "تفعيل حساب أسهل\nالرمز: $token\nرقم الهاتف: $phone";
    final url = "https://wa.me/$adminPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // Option 2: Check if device is already trusted (Smart Skip)
  Future<bool> isDeviceTrusted(String phone) async {
    final deviceId = await getDeviceId();
    final snap = await _db.collection('trusted_devices')
        .doc(phone)
        .get();
    
    if (snap.exists) {
      List trustedIds = snap.data()?['ids'] ?? [];
      return trustedIds.contains(deviceId);
    }
    return false;
  }

  // Register device as trusted after successful verification
  Future<void> trustDevice(String phone) async {
    final deviceId = await getDeviceId();
    await _db.collection('trusted_devices').doc(phone).set({
      'ids': FieldValue.arrayUnion([deviceId]),
      'last_verified': DateTime.now(),
    }, SetOptions(merge: true));
  }
}
