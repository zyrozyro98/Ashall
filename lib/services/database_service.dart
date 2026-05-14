import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/transaction.dart';
import '../models/app_user.dart';
import '../models/system_settings.dart';
import 'dart:io';


class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  // --- System Settings ---
  Stream<AppSystemSettings> getSystemSettings() {
    return _db.collection('system_settings').doc('global').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppSystemSettings.fromMap(doc.data()!);
      }
      return AppSystemSettings(); // Return defaults
    });
  }

  Future<void> updateSystemSettings(AppSystemSettings settings) async {
    await _db.collection('system_settings').doc('global').set(settings.toMap(), SetOptions(merge: true));
  }
  
  // --- Profile Management ---
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).update({'isOnline': isOnline});
  }

  Future<bool> hasActiveUserOrders(String uid) async {
    final query = await _db.collection('orders').get(); // since there's multiple collections for roles? No it's in orders collection.
    // wait, an order has customerId, merchantId, driverId.
    // to be safe, search across all fields if they match uid and status isn't completed/cancelled.
    bool hasActive = false;
    for (var doc in query.docs) {
      final data = doc.data();
      if ((data['customerId'] == uid || data['merchantId'] == uid || data['driverId'] == uid)) {
        int status = data['status'] ?? 0;
        if (status != OrderStatus.delivered.index && status != OrderStatus.cancelled.index) {
          hasActive = true;
          break;
        }
      }
    }
    return hasActive;
  }

  Future<void> updateUserPhone(String uid, String newPhone) async {
    await _db.collection('users').doc(uid).update({
      'phone': newPhone,
      'lastPhoneChange': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<AppTransaction>> getUserTransactions(String uid) {
    return _db.collection('transactions')
      .where('userId', isEqualTo: uid)
      .snapshots().map((snap) {
        final txs = snap.docs.map((doc) => AppTransaction.fromMap(doc.data(), doc.id)).toList();
        txs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return txs;
      });
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // --- Products ---
  // Add new product (Merchant role)
  Future<void> addProduct(Product p) async {
    Map<String, dynamic> data = p.toMap();
    // Force essential flags if missing
    data['isAvailable'] = true;
    data['isPromoted'] = data['isPromoted'] ?? false;
    data['timestamp'] = FieldValue.serverTimestamp();
    
    await _db.collection('products').add(data);
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
    return _db.collection('products')
      .where('isPromoted', isEqualTo: true)
      .where('isAvailable', isEqualTo: true)
      .snapshots().map((snap) =>
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
  // Create multiple orders (Customer) with optional balance deduction
  Future<void> placeOrders(List<AppOrder> orders, String uid, PaymentMethod method) async {
    if (orders.isEmpty) return;
    final double grandTotal = orders.fold(0.0, (double sum, AppOrder o) => sum + o.totalPrice);
    
    await _db.runTransaction((transaction) async {
      // Determine if we need to check/deduct balance
      if (method == PaymentMethod.balance) {
        DocumentReference userRef = _db.collection('users').doc(uid);
        DocumentReference settingsRef = _db.collection('system_settings').doc('global');
        
        DocumentSnapshot userSnap = await transaction.get(userRef);
        DocumentSnapshot settingsSnap = await transaction.get(settingsRef);
        
        String currencySymbol = (settingsSnap.data() as Map<String, dynamic>?)?['currencySymbol'] ?? 'AED';
        double currentBalance = (userSnap.data() as Map<String, dynamic>?)?['balance']?.toDouble() ?? 0.0;
        
        if (currentBalance < grandTotal) {
          throw Exception("عذراً، رصيدك غير كافٍ لإتمام هذه العملية (${grandTotal.toStringAsFixed(2)} $currencySymbol)");
        }
        
        // Deduction
        transaction.update(userRef, {'balance': currentBalance - grandTotal});
        
        // Transaction log for payment
        DocumentReference txRef = _db.collection('transactions').doc();
        transaction.set(txRef, {
          'userId': uid,
          'amount': grandTotal,
          'status': TransactionStatus.approved.index,
          'type': TransactionType.payment.index,
          'referenceNumber': 'ORD-AUTO-${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': FieldValue.serverTimestamp(),
          'note': 'دفع قيمة طلب بمبلغ: $grandTotal'
        });
      } else if (method == PaymentMethod.walletCode) {
        // Record pending transaction for admin approval
        DocumentReference txRef = _db.collection('transactions').doc();
        transaction.set(txRef, {
          'userId': uid,
          'amount': grandTotal,
          'status': TransactionStatus.pending.index,
          'type': TransactionType.recharge.index,
          'referenceNumber': orders.first.walletCode ?? 'N/A',
          'timestamp': FieldValue.serverTimestamp(),
          'note': 'تحويل خارجي معلق برقم: ${orders.first.walletCode}'
        });
      }

      // Finally, place the individual merchant orders
      for (var order in orders) {
        DocumentReference orderRef = _db.collection('orders').doc();
        // Ensure customerId is identical to uid for security rules
        final data = order.toMap();
        data['customerId'] = uid; 
        transaction.set(orderRef, data);
      }
    });
  }

  // Create Order (Customer) - Keep for backward compatibility or single direct orders
  Future<void> createOrder(AppOrder order) async {
    await _db.collection('orders').add(order.toMap());
  }

  // Real-time stream for a specific order
  Stream<AppOrder> getOrderStream(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) =>
      AppOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id));
  }

  // Get orders for customer
  Stream<List<AppOrder>> getCustomerOrders(String customerId) {
    return _db.collection('orders')
      .where('customerId', isEqualTo: customerId)
      .snapshots().map((snap) {
        final orders = snap.docs.map((doc) => AppOrder.fromMap(doc.data(), doc.id)).toList();
        orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return orders;
      });
  }

  // Get orders for merchant
  Stream<List<AppOrder>> getMerchantOrders(String merchantId) {
    return _db.collection('orders')
      .where('merchantId', isEqualTo: merchantId)
      .snapshots().map((snap) {
        final orders = snap.docs.map((doc) => AppOrder.fromMap(doc.data(), doc.id)).toList();
        orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return orders;
      });
  }

  // Get orders for driver
  Stream<List<AppOrder>> getDriverOrders(String driverId) {
    return _db.collection('orders')
      .where('driverId', isEqualTo: driverId)
      .snapshots().map((snap) {
        final orders = snap.docs.map((doc) => AppOrder.fromMap(doc.data(), doc.id)).toList();
        orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return orders;
      });
  }

  // Get available orders (Driver)
  Stream<List<AppOrder>> getAvailableOrders() {
    return _db.collection('orders')
      .where('status', whereIn: [OrderStatus.pending.index, OrderStatus.preparing.index, OrderStatus.ready.index])
      .snapshots().map((snap) {
        final orders = snap.docs
          .map((doc) => AppOrder.fromMap(doc.data(), doc.id))
          .where((order) => order.driverId == null || order.driverId!.isEmpty)
          .toList();
        orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return orders;
      });
  }

  Future<bool> assignDriverToOrder(String orderId, String driverId) async {
    bool success = false;
    await _db.runTransaction((transaction) async {
      DocumentReference orderRef = _db.collection('orders').doc(orderId);
      DocumentSnapshot snap = await transaction.get(orderRef);
      if (snap.exists) {
        Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
        // Securely check if driverId is not set
        if (data['driverId'] == null || data['driverId'].toString().isEmpty) {
          transaction.update(orderRef, {'driverId': driverId});
          success = true;
        } else {
          success = false;
        }
      }
    });
    return success;
  }

  // Order status update
  Future<void> updateOrderStatus(String orderId, OrderStatus status, {String? driverId, GeoPoint? driverLoc}) async {
    // Handle refund logic for customer cancellations or merchant rejections
    if (status == OrderStatus.cancelled) {
        final doc = await _db.collection('orders').doc(orderId).get();
        if (doc.exists) {
            final oData = doc.data()!;
            final pMethod = PaymentMethod.values[oData['paymentMethod']];
            if (pMethod == PaymentMethod.balance) {
                final customerId = oData['customerId'];
                final amount = (oData['totalPrice'] ?? 0.0).toDouble();

                await _db.runTransaction((transaction) async {
                    final userRef = _db.collection('users').doc(customerId);
                    final userSnap = await transaction.get(userRef);
                    if (userSnap.exists) {
                        double bal = (userSnap.data()?['balance'] ?? 0.0).toDouble();
                        transaction.update(userRef, {'balance': bal + amount});
                        
                        // Transaction history record for the refund
                        final refTxRef = _db.collection('transactions').doc();
                        transaction.set(refTxRef, {
                            'userId': customerId,
                            'amount': amount,
                            'type': TransactionType.refund.index,
                            'status': TransactionStatus.approved.index,
                            'timestamp': FieldValue.serverTimestamp(),
                            'note': 'استرداد لمبلغ الطلب: #$orderId'
                        });
                    }
                });
            }
        }
    }

    Map<String, dynamic> data = {
      'status': status.index,
    };
    if (driverId != null) data['driverId'] = driverId;
    if (driverLoc != null) data['driverLoc'] = driverLoc;

    await _db.collection('orders').doc(orderId).update(data);
  }

  // --- Financial Operations Management ---

  // Request a recharge (Pending)
  Future<void> requestRecharge(AppTransaction tx) async {
    await _db.collection('transactions').add({
      'userId': tx.userId,
      'amount': tx.amount,
      'type': TransactionType.recharge.index,
      'status': TransactionStatus.pending.index,
      'referenceNumber': tx.referenceNumber,
      'timestamp': FieldValue.serverTimestamp(),
      'note': 'طلب شحن مرجع: ${tx.referenceNumber}',
    });
  }

  // Request a withdrawal (Held immediately)
  Future<void> requestWithdrawal(AppTransaction tx) async {
    final userRef = _db.collection('users').doc(tx.userId);
    final settingsRef = _db.collection('system_settings').doc('global');
    
    await _db.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final settingsSnap = await transaction.get(settingsRef);
      if (!userSnap.exists) throw Exception("المستخدم غير موجود");
      
      String currencySymbol = settingsSnap.data()?['currencySymbol'] ?? 'AED';
      double currentBal = (userSnap.data()?['balance'] ?? 0.0).toDouble();
      if (currentBal < tx.amount) {
        throw Exception("عذراً، رصيدك غير كافٍ لسحب هذا المبلغ. متاح: $currentBal $currencySymbol");
      }

      // Deduct immediately to prevent double-spending
      transaction.update(userRef, {'balance': currentBal - tx.amount});
      
      // Create pending withdrawal transaction
      final txRef = _db.collection('transactions').doc();
      transaction.set(txRef, {
        'userId': tx.userId,
        'amount': tx.amount,
        'type': TransactionType.withdrawal.index,
        'status': TransactionStatus.pending.index,
        'referenceNumber': 'WITHDRAW-REQ',
        'timestamp': FieldValue.serverTimestamp(),
        'note': tx.note ?? 'طلب سحب أرباح',
      });
    });
  }

  // Admin: Approve a transaction
  Future<void> approveTransaction(String txId, String userId, double amount) async {
    final txRef = _db.collection('transactions').doc(txId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((transaction) async {
      final txSnap = await transaction.get(txRef);
      if (!txSnap.exists) return;
      
      final type = TransactionType.values[txSnap.data()?['type'] ?? 0];
      
      // If it's a recharge, we only add the balance on APPROVAL
      if (type == TransactionType.recharge) {
        final userSnap = await transaction.get(userRef);
        double bal = (userSnap.data()?['balance'] ?? 0.0).toDouble();
        transaction.update(userRef, {'balance': bal + amount});
      }
      
      // If it's a withdrawal, the deduction already happened at request time.
      // So on approval, we just finalize the status.

      transaction.update(txRef, {
        'status': TransactionStatus.approved.index,
        'processedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Admin: Reject a transaction
  Future<void> rejectTransaction(String txId) async {
    final txRef = _db.collection('transactions').doc(txId);

    await _db.runTransaction((transaction) async {
      final txSnap = await transaction.get(txRef);
      if (!txSnap.exists) return;
      
      final type = TransactionType.values[txSnap.data()?['type'] ?? 0];
      final userId = txSnap.data()?['userId'];
      final amount = (txSnap.data()?['amount'] ?? 0.0).toDouble();

      // If it's a withdrawal, we must REFUND the held amount
      if (type == TransactionType.withdrawal) {
        final userRef = _db.collection('users').doc(userId);
        final userSnap = await transaction.get(userRef);
        double bal = (userSnap.data()?['balance'] ?? 0.0).toDouble();
        transaction.update(userRef, {'balance': bal + amount});
      }

      transaction.update(txRef, {
        'status': TransactionStatus.rejected.index,
        'processedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Update real-time location (Driver)
  // SMART CHOICE: تم إزالة Firestore من هنا لمنع استهلاك كوتا الكتابة المجانية (20 ألف)
  // الاعتماد الكامل على RTDB لتتبع السائق
  Future<void> updateDriverLocation(String orderId, GeoPoint loc) async {
    await _rtdb.ref('tracking/$orderId').set({
      'lat': loc.latitude,
      'lng': loc.longitude,
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<DatabaseEvent> getLiveLocationStream(String orderId) {
    return _rtdb.ref('tracking/$orderId').onValue;
  }

  // Merchant Settings Update
  Future<void> updateMerchantSettings(String userId, Map<String, dynamic> settings) async {
    await _db.collection('users').doc(userId).update(settings);
  }

  // --- Rating System ---
  Future<void> rateOrder(String orderId, double rating, String feedback) async {
    await _db.collection('orders').doc(orderId).update({
      'rating': rating,
      'feedback': feedback,
    });
  }
}

