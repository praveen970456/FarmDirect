import 'package:flutter/material.dart';

import 'models/account.dart';
import 'models/product.dart';
import 'screens/auth_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manage_products_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const FarmDirectApp());
}

class FarmDirectApp extends StatelessWidget {
  const FarmDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmDirect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: forestGreen, primary: forestGreen),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainShell(),
    );
  }
}

// Holds the products and cart for the whole app and the bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();
  List<Product> _products = [];
  List<CartItem> _cart = [];
  int _tab = 0;
  bool _loading = true;
  Account? _activeAccount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load saved products and cart (samples are added on first launch only).
  Future<void> _loadData() async {
    final products = await _storage.loadProducts();
    final cart = await _storage.loadCart();
    final account = await _auth.loadSession();
    if (!mounted) return;
    setState(() {
      _products = products;
      _cart = cleanCart(products, cart);
      _activeAccount = account;
      _loading = false;
    });
  }

  Future<void> _login(String name, String password, AccountRole role) async {
    final account =
        await _auth.login(name: name, password: password, role: role);
    if (!mounted) return;
    setState(() {
      _activeAccount = account;
      _tab = 0;
    });
  }

  Future<void> _register(String name, String password, AccountRole role) async {
    final account =
        await _auth.register(name: name, password: password, role: role);
    if (!mounted) return;
    setState(() {
      _activeAccount = account;
      _tab = 0;
    });
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    setState(() {
      _activeAccount = null;
      _tab = 0;
    });
  }

  bool get _isCustomer => _activeAccount?.role == AccountRole.customer;

  int get _cartCount {
    int count = 0;
    for (final item in _cart) {
      count += item.quantity;
    }
    return count;
  }

  void _showMessage(String text) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 1)));
  }

  void _addToCart(Product product) {
    if (!_isCustomer) {
      _showMessage('Only customers can add products to the cart.');
      return;
    }
    final index = _cart.indexWhere((c) => c.productId == product.id);
    final current = index == -1 ? 0 : _cart[index].quantity;

    // Never allow more than the stock.
    if (current + 1 > product.stock) {
      _showMessage(
          'Only ${product.stock} ${product.unit} of ${product.name} available');
      return;
    }

    setState(() {
      if (index == -1) {
        _cart.add(CartItem(productId: product.id, quantity: 1));
      } else {
        _cart[index].quantity = current + 1;
      }
    });
    _storage.saveCart(_cart);
    _showMessage('${product.name} added to cart');
  }

  void _changeQuantity(String productId, int change) {
    if (!_isCustomer) {
      _showMessage('Only customers can change cart quantities.');
      return;
    }
    final index = _cart.indexWhere((c) => c.productId == productId);
    if (index == -1) return;

    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) return;
    final product = _products[productIndex];
    final newQuantity = _cart[index].quantity + change;

    if (newQuantity > product.stock) {
      _showMessage('Only ${product.stock} ${product.unit} available');
      return;
    }

    setState(() {
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = newQuantity;
      }
    });
    _storage.saveCart(_cart);
  }

  void _removeFromCart(String productId) {
    if (!_isCustomer) {
      _showMessage('Only customers can remove products from the cart.');
      return;
    }
    setState(() => _cart.removeWhere((c) => c.productId == productId));
    _storage.saveCart(_cart);
  }

  // Merge only this farmer's listings; the complete marketplace stays intact.
  void _saveFarmerProducts(List<Product> products) {
    final account = _activeAccount;
    if (account == null || account.role != AccountRole.farmer) {
      _showMessage('Only farmers can manage product listings.');
      return;
    }

    final ownedIds = _products
        .where((product) => product.farmerId == account.id)
        .map((product) => product.id)
        .toSet();
    final productIds = <String>{};
    for (final product in products) {
      if (product.farmerId != account.id ||
          !productIds.add(product.id) ||
          (_products.any((saved) => saved.id == product.id) &&
              !ownedIds.contains(product.id))) {
        _showMessage('You can only manage your own products.');
        return;
      }
    }

    final merged = _products
        .where((product) => product.farmerId != account.id)
        .toList()
      ..addAll(products);
    setState(() {
      _products = merged;
      _cart = cleanCart(merged, _cart);
    });
    _storage.saveProducts(_products);
    _storage.saveCart(_cart);
  }

  // Reduce stock, clear the cart, and return a new order number.
  String _placeOrder() {
    if (!_isCustomer) {
      _showMessage('Only customers can place orders.');
      return '';
    }
    final updated = <Product>[];
    for (final product in _products) {
      int ordered = 0;
      for (final item in _cart) {
        if (item.productId == product.id) ordered = item.quantity;
      }
      final newStock = product.stock - ordered;
      updated.add(product.copyWith(stock: newStock < 0 ? 0 : newStock));
    }

    setState(() {
      _products = updated;
      _cart = [];
    });
    _storage.saveProducts(_products);
    _storage.saveCart(_cart);
    return generateOrderNumber();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final account = _activeAccount;
    if (account == null) {
      return AuthScreen(onLogin: _login, onRegister: _register);
    }

    if (account.role == AccountRole.farmer) {
      return ManageProductsScreen(
        products: _products,
        farmerId: account.id,
        farmerName: account.name,
        onSave: _saveFarmerProducts,
        onLogout: _logout,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            products: _products,
            cartCount: _cartCount,
            customerName: account.name,
            onAddToCart: _addToCart,
            onOpenCart: () => setState(() => _tab = 1),
            onLogout: _logout,
          ),
          CartScreen(
            products: _products,
            cart: _cart,
            onChangeQuantity: _changeQuantity,
            onRemove: _removeFromCart,
            onPlaceOrder: _placeOrder,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$_cartCount'),
              isLabelVisible: _cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$_cartCount'),
              isLabelVisible: _cartCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
