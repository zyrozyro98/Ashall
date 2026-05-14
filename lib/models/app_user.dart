import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  customer,
  merchant,
  driver,
  admin
}

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImage;
  final String? phone;
  final DateTime? lastPhoneChange; // Track when phone was last changed
  final double balance;
  final double rating;
  final bool isOnline;
  final String? fcmToken;
  final bool isPhoneVerified;
  
  // Merchant Specific Fields
  final String? storeName;
  final String? storeAddress;
  final GeoPoint? storeLocation;
  final String? workingHours;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    this.phone,
    this.lastPhoneChange,
    this.balance = 0.0,
    this.rating = 5.0,
    this.isOnline = false,
    this.fcmToken,
    this.isPhoneVerified = false,
    this.storeName,
    this.storeAddress,
    this.storeLocation,
    this.workingHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.index, // Changed to use index for serialization
      'profileImage': profileImage,
      'phone': phone,
      'lastPhoneChange': lastPhoneChange?.toIso8601String(),
      'balance': balance,
      'rating': rating,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'isPhoneVerified': isPhoneVerified,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storeLocation': storeLocation,
      'workingHours': workingHours,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: _parseRole(map['role']),
      profileImage: map['profileImage']?.toString(),
      phone: map['phone']?.toString(),
      lastPhoneChange: map['lastPhoneChange'] != null ? DateTime.tryParse(map['lastPhoneChange'].toString()) : null,
      balance: _parseDouble(map['balance']),
      rating: _parseDouble(map['rating'] ?? 5.0),
      isOnline: map['isOnline'] == true,
      fcmToken: map['fcmToken']?.toString(),
      isPhoneVerified: map['isPhoneVerified'] == true,
      storeName: map['storeName']?.toString(),
      storeAddress: map['storeAddress']?.toString(),
      storeLocation: map['storeLocation'] is GeoPoint ? map['storeLocation'] : null,
      workingHours: map['workingHours']?.toString(),
    );
  }

  static UserRole _parseRole(dynamic roleData) {
    if (roleData == null) return UserRole.customer;
    if (roleData is num) {
      int r = roleData.toInt();
      if (r >= 0 && r < UserRole.values.length) {
        return UserRole.values[r];
      }
    } else if (roleData is String) {
      String r = roleData.toLowerCase();
      if (r.contains('admin') || r.contains('manager')) return UserRole.admin;
      if (r.contains('merchant')) return UserRole.merchant;
      if (r.contains('driver')) return UserRole.driver;
      
      int? parsedNum = int.tryParse(r);
      if (parsedNum != null && parsedNum >= 0 && parsedNum < UserRole.values.length) {
        return UserRole.values[parsedNum];
      }
    }
    return UserRole.customer;
  }

  static double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
