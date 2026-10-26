import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';
import '../widgets/product_card.dart';

// Screen 3: selected products, quantities, total and demo order.
class CartScreen extends StatelessWidget {
  final List<Product> products;
  final List<CartItem> cart;
  final void Function(String productId, int change) onChangeQuantity;
  final void Function(String productId) onRemove;
  final String Function() onPlaceOrder; // returns the new order number

  const CartScreen({
    super.key,
    required this.products,
    required this.cart,
    required this.onChangeQuantity,
    required this.onRemove,
    required this.onPlaceOrder,
  });

  Product? _findProduct(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _placeOrder(BuildContext context) {
    final total = calculateTotal(products, cart); // total before the cart is cleared
    final orderNumber = onPlaceOrder();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: forestGreen, size: 48),
        title: const Text('Order placed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order number: $orderNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Total: ${formatRupees(total)}'),
            const SizedBox(height: 10),
            const Text('This is a demo order. No payment is taken.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = calculateTotal(products, cart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.black38),
                  SizedBox(height: 8),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Add fresh products from the Home tab', style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final product = _findProduct(item.productId);
                      if (product == null) return const SizedBox.shrink();

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: lightGreen,
                                    child: Icon(categoryIcon(product.category), color: forestGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text('${formatPrice(product.price)}/${product.unit} • by ${product.farmer}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => onRemove(product.id),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => onChangeQuantity(product.id, -1),
                                  ),
                                  Text('${item.quantity}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    // Cannot go above the available stock.
                                    onPressed: item.quantity >= product.stock
                                        ? null
                                        : () => onChangeQuantity(product.id, 1),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatRupees(product.price * item.quantity),
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold, color: forestGreen),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            formatRupees(total),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: forestGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _placeOrder(context),
                          icon: const Icon(Icons.check),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Place Demo Order'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
