import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

// The 8 products added on the very first launch.
List<Product> sampleProducts() {
  return const [
    Product(id: 'p1', name: 'Tomatoes', farmer: 'Ramesh Kumar', category: 'Vegetables', price: 40, unit: 'kg', stock: 50),
    Product(id: 'p2', name: 'Potatoes', farmer: 'Lakshmi Devi', category: 'Vegetables', price: 30, unit: 'kg', stock: 80),
    Product(id: 'p3', name: 'Carrots', farmer: 'Suresh Reddy', category: 'Vegetables', price: 55, unit: 'kg', stock: 35),
    Product(id: 'p4', name: 'Mangoes', farmer: 'Anita Rao', category: 'Fruits', price: 120, unit: 'kg', stock: 40),
    Product(id: 'p5', name: 'Bananas', farmer: 'Venkat Naidu', category: 'Fruits', price: 60, unit: 'dozen', stock: 30),
    Product(id: 'p6', name: 'Apples', farmer: 'Harpreet Singh', category: 'Fruits', price: 150, unit: 'kg', stock: 25),
    Product(id: 'p7', name: 'Rice', farmer: 'Gopal Sharma', category: 'Grains', price: 65, unit: 'kg', stock: 100),
    Product(id: 'p8', name: 'Wheat', farmer: 'Mohan Lal', category: 'Grains', price: 35, unit: 'kg', stock: 90),
  ];
}

// Saves and loads products and the cart as JSON text.
class StorageService {
  static const String _productsKey = 'products';
  static const String _cartKey = 'cart';

  Future<List<Product>> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_productsKey);

    // Nothing saved yet = first launch, so add the sample products once.
    if (text == null) {
      final samples = sampleProducts();
      await saveProducts(samples);
      return samples;
    }

    try {
      final list = jsonDecode(text) as List;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Recover from corrupted local data and persist a fresh starter catalogue.
      final samples = sampleProducts();
      await saveProducts(samples);
      return samples;
    }
  }

  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_productsKey, jsonEncode(products.map((p) => p.toJson()).toList()));
  }

  Future<List<CartItem>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_cartKey);
    if (text == null) return [];

    try {
      final list = jsonDecode(text) as List;
      return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCart(List<CartItem> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart.map((c) => c.toJson()).toList()));
  }
}
