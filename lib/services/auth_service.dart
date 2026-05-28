import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../utils/phone_utils.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get userStatus => _auth.authStateChanges();

  // Sign In
  Future<AppUser?> signIn(String email, String password) async {
    try {
      UserCredential res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Ensure we have a Firestore doc for this user
      if (res.user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(res.user!.uid).get();
        if (doc.exists) {
          return AppUser.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicMessage(e.code));
    }
  }

  // Register / Sign Up
  Future<AppUser> signUp(String email, String password, String name, UserRole role, {String? phone}) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? u = res.user;

      if (u == null) throw Exception("فشل نظام التوثيق اللحظي. يرجى المحاولة لاحقاً.");

      // Fetch token with a timeout to avoid hangs
      String fcm = "";
      try {
        fcm = await NotificationService().getToken().timeout(const Duration(seconds: 5)) ?? "";
      } catch (_) {}

      AppUser appU = AppUser(
        uid: u.uid, 
        email: email, 
        name: name, 
        role: role, 
        phone: phone,
        lastPhoneChange: null, // Allow first change if they made a mistake
        fcmToken: fcm
      );
      try {
        await _db.collection('users').doc(u.uid).set(appU.toMap(), SetOptions(merge: true));
        return appU;
      } catch (dbError) {
        // Fallback: If Firestore fails, we sign out to ensure a clean state
        await _auth.signOut();
        debugPrint("Firestore User Creation Error: $dbError");
        throw Exception("فشل تسجيل البيانات السحابية: $dbError");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicMessage(e.code));
    } catch (otherError) {
      throw Exception("حدث خطأ غير متوقع: $otherError");
    }
  }

  // Recovery: Re-create missing user document
  Future<void> syncUserDoc(User u) async {
    final doc = await _db.collection('users').doc(u.uid).get();
    if (!doc.exists) {
       // Securely determine role dynamically based on exact email match ONLY
       String emailStr = (u.email ?? '').toLowerCase();
       UserRole defaultRole = UserRole.customer;
       
       // Add exact admin emails here to prevent unauthorized access
       const List<String> adminEmails = [
         'zyrozyro98@gmail.com',
         // 'admin@yourdomain.com', // add other exact emails here
       ];
       
       if (adminEmails.contains(emailStr)) {
         defaultRole = UserRole.admin;
       }
       
       AppUser appU = AppUser(
         uid: u.uid, 
         email: u.email ?? '', 
         name: u.displayName ?? 'مستخدم جديد', 
         role: defaultRole, 
       );
       await _db.collection('users').doc(u.uid).set(appU.toMap());
    }
  }

  // Fetch user data once
  Future<AppUser?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<AppUser?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots(includeMetadataChanges: true).map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUser.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update FCM token in Firestore
  Future<void> updateFcmToken(String uid) async {
    try {
      String? token = await NotificationService().getToken().timeout(const Duration(seconds: 5));
      if (token != null && token.isNotEmpty) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
        debugPrint("FCM Token synchronized for user: $uid");
      }
    } catch (e) {
      debugPrint("Non-critical FCM Token update failure: $e");
    }
  }

  // --- Phone Linkage ---
  Future<void> linkPhoneNumber(PhoneAuthCredential credential, String phone) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("لا يوجد مستخدم مسجل حالياً");

      // Attempt to link/update the phone number in Auth
      // If it exists, it updates; if not, it links.
      await user.updatePhoneNumber(credential);
      
      // Update Firestore
      await _db.collection('users').doc(user.uid).update({
        'phone': phone,
        'lastPhoneChange': DateTime.now().toIso8601String(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicMessage(e.code));
    } catch (e) {
      throw Exception("فشل تحديث الرقم: $e");
    }
  }

  // --- Update Phone and Mapped Email ---
  Future<void> updatePhoneAndEmail(String rawPhone) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("لا يوجد مستخدم مسجل حالياً");

      final normalized = PhoneUtils.normalizePhone(rawPhone);
      final newEmail = "$normalized@ashall.com";
      final formattedPhone = "+$normalized";

      // 1. Update Firebase Auth Email
      // ignore: deprecated_member_use
      await user.updateEmail(newEmail);

      // 2. Update Firestore
      await _db.collection('users').doc(user.uid).update({
        'phone': formattedPhone,
        'email': newEmail,
        'isPhoneVerified': false,
        'lastPhoneChange': DateTime.now().toIso8601String(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(_getArabicMessage(e.code));
    } catch (e) {
      throw Exception("فشل تحديث رقم الهاتف: $e");
    }
  }

  String _getArabicMessage(String code) {
    switch (code) {
      case 'user-not-found': return "المستخدم غير موجود";
      case 'wrong-password': return "كلمة المرور غير صحيحة";
      case 'email-already-in-use': return "البريد الإلكتروني مسجل بالفعل";
      case 'invalid-email': return "بريد إلكتروني غير صالح";
      case 'weak-password': return "كلمة المرور ضعيفة جداً";
      case 'credential-already-in-use': return "رقم الهاتف هذا مستخدم بالفعل في حساب آخر";
      case 'invalid-verification-code': return "كود التحقق غير صحيح";
      case 'too-many-requests': return "لقد تم إرسال طلبات كثيرة جداً، يرجى المحاولة لاحقاً";
      case 'requires-recent-login': return "من أجل الأمان، يرجى تسجيل الخروج ثم الدخول مجدداً لتحديث رقم الهاتف.";
      default: return "حدث خطأ ما، يرجى المحاولة لاحقاً ($code)";
    }
  }
}
