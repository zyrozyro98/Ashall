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
  final double balance;
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImage,
    this.phone,
    this.balance = 0.0,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.index, // Changed to use index for serialization
      'profileImage': profileImage,
      'phone': phone,
      'balance': balance,
      'fcmToken': fcmToken,
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
      balance: _parseDouble(map['balance']),
      fcmToken: map['fcmToken']?.toString(),
    );
  }

  static UserRole _parseRole(dynamic roleData) {
    if (roleData is int) {
      if (roleData >= 0 && roleData < UserRole.values.length) {
        return UserRole.values[roleData];
      }
    } else if (roleData is String) {
      String r = roleData.toLowerCase();
      if (r.contains('admin')) return UserRole.admin;
      if (r.contains('merchant')) return UserRole.merchant;
      if (r.contains('driver')) return UserRole.driver;
    }
    return UserRole.customer;
  }

  static double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
