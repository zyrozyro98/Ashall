class Product {
  final String id;
  final String merchantId;
  final String merchantName;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final String category;
  final bool isPromoted;


  Product({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isAvailable = true,
    this.category = "غير مصنف",
    this.isPromoted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'category': category,
      'isPromoted': isPromoted,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      merchantId: map['merchantId']?.toString() ?? '',
      merchantName: map['merchantName']?.toString() ?? 'Unk Merchant',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: _parseDouble(map['price']),
      imageUrl: map['imageUrl']?.toString() ?? '',
      isAvailable: _parseBool(map['isAvailable'], true),
      category: map['category']?.toString() ?? 'أخرى',
      isPromoted: _parseBool(map['isPromoted'], false),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic val, bool defaultValue) {
    if (val is bool) return val;
    if (val is String) {
      if (val.toLowerCase() == 'true') return true;
      if (val.toLowerCase() == 'false') return false;
    }
    return defaultValue;
  }
}
