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

  bool addItem(String productId, String name, double price) {
    // If the item is already in the cart, do NOT add it again (prevents duplication)
    if (!_items.containsKey(productId)) {
      _items.putIfAbsent(productId, () => OrderItem(
        productId: productId, 
        name: name, 
        quantity: 1, 
        price: price
      ));
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
