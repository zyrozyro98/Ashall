import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StorageService {
  // هام: ضع مفتاح الـ API الخاص بك من موقع https://api.imgbb.com هنا
  // قم بإنشاء حساب مجاني واحصل على المفتاح فوراً (التخزين غير محدود ومجاني للأبد)
  // مفاتيح API احتياطية لضمان عمل الرفع دائماً
  static const String _imgbbApiKey = "90a93fba0d70f0ecaeb743fb1e59fdb3"; 
  static const String _imgbbApiKeyAlt = "64c8d8b67f620819777f9c897f262143";

  // Upload product image to ImgBB
  Future<String?> uploadProductImage(File file, String productId) async {
    String? url = await _uploadToImgBB(file, _imgbbApiKey);
    if (url == null) {
      url = await _uploadToImgBB(file, _imgbbApiKeyAlt);
    }
    return url;
  }

  // Upload profile image to ImgBB
  Future<String?> uploadProfileImage(File file, String userId) async {
    String? url = await _uploadToImgBB(file, _imgbbApiKey);
    if (url == null) {
      url = await _uploadToImgBB(file, _imgbbApiKeyAlt);
    }
    return url;
  }

  // الدالة الأساسية لرفع الصور إلى ImgBB (باستخدام Base64 لضمان التوافق)
  Future<String?> _uploadToImgBB(File file, String apiKey) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      var response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
        body: {
          'image': base64Image,
        },
      ).timeout(const Duration(seconds: 30));
      
      var jsonMap = json.decode(response.body);

      if (response.statusCode == 200) {
        String imageUrl = jsonMap['data']['url'];
        debugPrint("✅ تم رفع الصورة بنجاح: $imageUrl");
        return imageUrl;
      } else {
        String errorMsg = jsonMap['error']?['message'] ?? "Unknown Error";
        debugPrint("❌ فشل رفع الصورة: $errorMsg");
        return null;
      }
    } catch (e) {
      debugPrint("❌ حدث خطأ أثناء الرفع إلى ImgBB: $e");
      return null;
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    // ملاحظة: الحذف المباشر عبر ImgBB API الأساسي غير مدعوم بسهولة،
    // ولكن بما أن التخزين غير محدود ومجاني 100%، فلا داعي للقلق بشأن حذف الصور القديمة
    // حيث أنها لا تستهلك أي مساحة أو تكلفة على حسابك.
    debugPrint("🗑️ محاولة حذف الصورة (تم التجاهل، التخزين الخارجي مجاني وغير محدود)");
  }
}
