import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transaction.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Wallet & Transactions ---
  Future<void> requestRecharge(AppTransaction tx) async {
    await _db.collection('transactions').add(tx.toMap());
  }

  Stream<List<AppTransaction>> getUserTransactions(String uid) {
    return _db.collection('transactions')
      .where('userId', isEqualTo: uid)
      .orderBy('timestamp', descending: true)
      .snapshots().map((snap) => snap.docs.map((doc) => AppTransaction.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> approveTransaction(String txId, String userId, double amount) async {
    await _db.runTransaction((transaction) async {
      DocumentReference txRef = _db.collection('transactions').doc(txId);
      DocumentReference userRef = _db.collection('users').doc(userId);
      
      DocumentSnapshot userSnap = await transaction.get(userRef);
      double currentBalance = (userSnap.data() as Map<String, dynamic>?)?['balance'] ?? 0.0;
      
      transaction.update(txRef, {'status': TransactionStatus.approved.index});
      transaction.update(userRef, {'balance': currentBalance + amount});
    });
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // --- Products ---
  // Add new product (Merchant role)
  Future<void> addProduct(Product p) async {
    await _db.collection('products').add(p.toMap());
  }

  // Fetch products by merchant
  Stream<List<Product>> getMerchantProducts(String merchantId) {
    return _db.collection('products')
      .where('merchantId', isEqualTo: merchantId)
      .snapshots().map((snap) =>
        snap.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Fetch all available products (Customer role)
  Stream<List<Product>> getPromotedProducts() {
    return _db.collection('products').where('isPromoted', isEqualTo: true).snapshots().map((snap) =>
      snap.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Product>> getAllProducts() {
    return _db.collection('products')
      .where('isAvailable', isEqualTo: true)
      .snapshots().map((snap) =>
        snap.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  // Update status product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(productId).update(data);
  }

  // -- ORDER MANAGEMENT --
  // Create Order (Customer)
  Future<void> createOrder(AppOrder order) async {
    await _db.collection('orders').add(order.toMap());
  }

  // Get orders for customer
  Stream<List<AppOrder>> getCustomerOrders(String customerId) {
    return _db.collection('orders')
      .where('customerId', isEqualTo: customerId)
      .orderBy('timestamp', descending: true)
      .snapshots().map((snap) =>
        snap.docs.map((doc) => AppOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Get orders for merchant
  Stream<List<AppOrder>> getMerchantOrders(String merchantId) {
    return _db.collection('orders')
      .where('merchantId', isEqualTo: merchantId)
      .orderBy('timestamp', descending: true)
      .snapshots().map((snap) =>
        snap.docs.map((doc) => AppOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Get available orders (Driver)
  Stream<List<AppOrder>> getAvailableOrders() {
    return _db.collection('orders')
      .where('status', isEqualTo: 'pending')
      .orderBy('timestamp', descending: true)
      .snapshots().map((snap) =>
        snap.docs.map((doc) => AppOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Order status update
  Future<void> updateOrderStatus(String orderId, OrderStatus status, {String? driverId, GeoPoint? driverLoc}) async {
    Map<String, dynamic> data = {
      'status': status.toString().split('.').last,
    };
    if (driverId != null) data['driverId'] = driverId;
    if (driverLoc != null) data['driverLoc'] = driverLoc;

    await _db.collection('orders').doc(orderId).update(data);
  }

  // Update real-time location (Driver)
  Future<void> updateDriverLocation(String orderId, GeoPoint loc) async {
    await _db.collection('orders').doc(orderId).update({'driverLoc': loc});
  }
}
