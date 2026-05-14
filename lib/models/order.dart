import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending, preparing, ready, pickedUp, delivered, cancelled
}

enum PaymentMethod { cash, balance, walletCode }

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String merchantId; // Track which merchant this came from

  OrderItem({required this.productId, required this.name, required this.quantity, required this.price, required this.merchantId});

  Map<String, dynamic> toMap() => {'productId': productId, 'name': name, 'quantity': quantity, 'price': price, 'merchantId': merchantId};
  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] ?? '',
    name: map['name'] ?? '',
    quantity: map['quantity'] ?? 1,
    price: (map['price'] ?? 0.0).toDouble(),
    merchantId: map['merchantId'] ?? 'unknown'
  );
}

class AppOrder {
  final String id;
  final String customerId;
  final String? driverId;
  final String merchantId;
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final DateTime timestamp;
  final PaymentMethod paymentMethod;
  final String? walletCode; // Code for "Mobile Wallet" payments
  final GeoPoint? customerLoc;
  final GeoPoint? merchantLoc;
  final GeoPoint? driverLoc;
  final double? rating;
  final String? feedback;
  final double deliveryFee;

  AppOrder({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.merchantId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.timestamp,
    this.paymentMethod = PaymentMethod.cash,
    this.walletCode,
    this.customerLoc,
    this.merchantLoc,
    this.driverLoc,
    this.rating,
    this.feedback,
    required this.deliveryFee,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'driverId': driverId,
      'merchantId': merchantId,
      'items': items.map((i) => i.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.index,
      'timestamp': timestamp,
      'paymentMethod': paymentMethod.index,
      'walletCode': walletCode,
      'customerLoc': customerLoc,
      'merchantLoc': merchantLoc,
      'driverLoc': driverLoc,
      'rating': rating,
      'feedback': feedback,
      'deliveryFee': deliveryFee,
    };
  }

  factory AppOrder.fromMap(Map<String, dynamic> map, String docId) {
    return AppOrder(
      id: docId,
      customerId: map['customerId'] ?? '',
      driverId: map['driverId'],
      merchantId: map['merchantId'] ?? '',
      items: (map['items'] as List?)?.map((i) => OrderItem.fromMap(i)).toList() ?? [],
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: OrderStatus.values[map['status'] ?? 0],
      timestamp: map['timestamp'] != null ? (map['timestamp'] as Timestamp).toDate() : DateTime.now(),
      paymentMethod: PaymentMethod.values[map['paymentMethod'] ?? 0],
      walletCode: map['walletCode'],
      customerLoc: map['customerLoc'],
      merchantLoc: map['merchantLoc'],
      driverLoc: map['driverLoc'],
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      feedback: map['feedback'],
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
    );
  }
}
