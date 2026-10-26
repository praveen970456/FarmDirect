// Data models and small helper functions (pure Dart, easy to test).

class Product {
  final String id;
  final String name;
  final String farmer;
  final String? farmerId;
  final String category;
  final double price; // stored as a number, formatted only for display
  final String unit;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.farmer,
    this.farmerId,
    required this.category,
    required this.price,
    required this.unit,
    required this.stock,
  });

  static const List<String> categories = ['Vegetables', 'Fruits', 'Grains'];

  Product copyWith({
    String? name,
    String? farmer,
    String? farmerId,
    String? category,
    double? price,
    String? unit,
    int? stock,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      farmer: farmer ?? this.farmer,
      farmerId: farmerId ?? this.farmerId,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'farmer': farmer,
        'farmerId': farmerId,
        'category': category,
        'price': price,
        'unit': unit,
        'stock': stock,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        farmer: json['farmer'] as String,
        farmerId: json['farmerId'] as String?,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        unit: json['unit'] as String,
        stock: (json['stock'] as num).toInt(),
      );
}

// One line in the cart: which product and how many.
class CartItem {
  final String productId;
  int quantity;

  CartItem({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {'productId': productId, 'quantity': quantity};

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        quantity: (json['quantity'] as num).toInt(),
      );
}

// Form validation rules. Each returns an error message, or null when valid.
class Validators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final number = double.tryParse(value.trim());
    if (number == null || number.isNaN || number.isInfinite) {
      return 'Enter a valid number';
    }
    if (number <= 0) {
      return 'Price must be greater than zero';
    }
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock is required';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Stock must be a whole number';
    }
    if (number < 0) {
      return 'Stock cannot be negative';
    }
    return null;
  }
}

// Total = sum of (price x quantity) using the real product prices.
double calculateTotal(List<Product> products, List<CartItem> cart) {
  double total = 0;
  for (final item in cart) {
    for (final product in products) {
      if (product.id == item.productId) {
        total += product.price * item.quantity;
      }
    }
  }
  return total;
}

// Removes cart lines whose product is gone or out of stock,
// and lowers quantities that are above the available stock.
List<CartItem> cleanCart(List<Product> products, List<CartItem> cart) {
  final result = <CartItem>[];
  for (final item in cart) {
    final matches = products.where((p) => p.id == item.productId);
    if (matches.isEmpty) continue;
    final stock = matches.first.stock;
    if (stock <= 0 || item.quantity <= 0) continue;
    final quantity = item.quantity > stock ? stock : item.quantity;
    result.add(CartItem(productId: item.productId, quantity: quantity));
  }
  return result;
}

// Simple order number such as FD-482913.
String generateOrderNumber([DateTime? now]) {
  final time = now ?? DateTime.now();
  final digits = (time.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
  return 'FD-$digits';
}
