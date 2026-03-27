import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of User State
  Stream<User?> get userStatus => _auth.authStateChanges();

  // Create User with Role
  Future<AppUser?> signUp(String email, String password, String name, UserRole role) async {
    // Admin Auto-Promotion Override on Signup
    if (email.toLowerCase() == 'zyrozyro98@gmail.com') {
      role = UserRole.admin;
    }
    
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? u = res.user;

      if (u != null) {
        String? fcm = await NotificationService().getToken();
        AppUser appU = AppUser(uid: u.uid, email: email, name: name, role: role, fcmToken: fcm);
        try {
          await _db.collection('users').doc(u.uid).set(appU.toMap());
          return appU;
        } catch (dbError) {
          // Rollback the authentication since DB creation failed!
          await u.delete();
          print("Firestore User Creation Error: $dbError");
          return null;
        }
      }
    } catch (e) {
      print("Signup Error: $e");
    }
    return null;
  }

  // Sign In
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Admin Auto-Promotion Override & FCM Token update
      String? token = await NotificationService().getToken();
      Map<String, dynamic> updates = {'fcmToken': token};
      
      if (res.user != null && email.toLowerCase() == 'zyrozyro98@gmail.com') {
        updates['role'] = UserRole.admin.index;
      }
      
      if (res.user != null) {
        await _db.collection('users').doc(res.user!.uid).update(updates).catchError((_) {});
      }
      
      return res;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // Get AppUser data
  Future<AppUser?> getUserData(String uid) async {
    DocumentSnapshot snap = await _db.collection('users').doc(uid).get();
    if (snap.exists) {
      return AppUser.fromMap(snap.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Stream of AppUser data (fixes startup race condition)
  Stream<AppUser?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (snap.exists) {
        return AppUser.fromMap(snap.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
