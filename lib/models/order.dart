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

  OrderItem({required this.productId, required this.name, required this.quantity, required this.price});

  Map<String, dynamic> toMap() => {'productId': productId, 'name': name, 'quantity': quantity, 'price': price};
  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'],
    name: map['name'],
    quantity: map['quantity'],
    price: (map['price'] ?? 0.0).toDouble()
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
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      paymentMethod: PaymentMethod.values[map['paymentMethod'] ?? 0],
      walletCode: map['walletCode'],
      customerLoc: map['customerLoc'],
      merchantLoc: map['merchantLoc'],
      driverLoc: map['driverLoc'],
    );
  }
}
