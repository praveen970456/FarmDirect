import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final int cartCount;
  final String customerName;
  final void Function(Product) onAddToCart;
  final VoidCallback onOpenCart;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.products,
    required this.cartCount,
    required this.customerName,
    required this.onAddToCart,
    required this.onOpenCart,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  String? _category; // null means "show all categories"

  // Products that match the search text and the selected category.
  List<Product> get _filtered {
    final query = _query.trim().toLowerCase();
    return widget.products.where((p) {
      final matchesCategory = _category == null || p.category == _category;
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.farmer.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Column(
        children: [
          // Green header with title, tagline, cart icon and search bar.
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
            decoration: const BoxDecoration(
              color: forestGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.agriculture, color: Colors.white, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FarmDirect',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Fresh from Farmers. Fair for Everyone.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            'Hello, ${widget.customerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onOpenCart,
                      icon: Badge(
                        label: Text('${widget.cartCount}'),
                        isLabelVisible: widget.cartCount > 0,
                        child: const Icon(Icons.shopping_cart, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search products or farmers',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category chips: tap to filter, tap again to show all.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                for (final category in Product.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(categoryIcon(category), size: 18, color: forestGreen),
                      label: Text(category),
                      selected: _category == category,
                      selectedColor: const Color(0xFFC8E6C9),
                      onSelected: (selected) {
                        setState(() => _category = selected ? category : null);
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Product grid (or an empty message).
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 56, color: Colors.black38),
                        SizedBox(height: 8),
                        Text('No products found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Try a different search or category', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive: more columns on wider screens.
                      final columns = constraints.maxWidth >= 600 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 280,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return ProductCard(
                            product: product,
                            onAdd: () => widget.onAddToCart(product),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
