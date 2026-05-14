import 'package:flutter/material.dart';
import '../models/order.dart';

class CartProvider with ChangeNotifier {
  final Map<String, OrderItem> _items = {};

  Map<String, OrderItem> get items => {..._items};

  int get itemCount {
    int count = 0;
    for (var item in _items.values) {
      count += item.quantity;
    }
    return count;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  bool addItem(String productId, String name, double price, String merchantId) {
    if (_items.containsKey(productId)) {
      var old = _items[productId]!;
      _items[productId] = OrderItem(
        productId: productId, 
        name: name, 
        quantity: old.quantity + 1, 
        price: price, 
        merchantId: merchantId
      );
    } else {
      _items.putIfAbsent(productId, () => OrderItem(
        productId: productId, 
        name: name, 
        quantity: 1, 
        price: price,
        merchantId: merchantId,
      ));
    }
    notifyListeners();
    return true;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeByOne(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      final old = _items[productId]!;
      _items[productId] = OrderItem(
        productId: productId, 
        name: old.name, 
        quantity: old.quantity - 1, 
        price: old.price, 
        merchantId: old.merchantId
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
