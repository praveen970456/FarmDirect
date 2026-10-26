import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';

// Local icon for each category (no images needed, works offline).
IconData categoryIcon(String category) {
  switch (category) {
    case 'Fruits':
      return Icons.local_florist;
    case 'Grains':
      return Icons.grass;
    default:
      return Icons.eco;
  }
}

// Reusable rounded card used in the Home grid.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack: icon in the middle, category label on top.
          Stack(
            children: [
              Container(
                height: 80,
                width: double.infinity,
                alignment: Alignment.center,
                color: lightGreen,
                child: Icon(categoryIcon(product.category), size: 44, color: forestGreen),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: forestGreen),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${product.farmer}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatPrice(product.price)}/${product.unit}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: forestGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  outOfStock ? 'Out of stock' : 'Stock: ${product.stock} ${product.unit}',
                  style: TextStyle(fontSize: 12, color: outOfStock ? Colors.red : Colors.black54),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: outOfStock ? null : onAdd,
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('Add to Cart'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
