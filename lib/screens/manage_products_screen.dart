import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/product.dart';
import '../utils/currency_formatter.dart';
import '../widgets/product_card.dart';

// Screen 2: list of products with add, edit and delete.
class ManageProductsScreen extends StatelessWidget {
  final List<Product> products;
  final String farmerId;
  final String farmerName;
  final void Function(List<Product>) onSave;
  final VoidCallback onLogout;

  const ManageProductsScreen({
    super.key,
    required this.products,
    required this.farmerId,
    required this.farmerName,
    required this.onSave,
    required this.onLogout,
  });

  List<Product> get _ownedProducts => products.where((product) => product.farmerId == farmerId).toList();

  Future<void> _addProduct(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(farmerId: farmerId, farmerName: farmerName),
      ),
    );
    if (result != null) {
      if (result.farmerId != farmerId) {
        messenger.showSnackBar(const SnackBar(content: Text('You can only add products to your own account.')));
        return;
      }
      onSave([..._ownedProducts, result]);
      messenger.showSnackBar(const SnackBar(content: Text('Product added')));
    }
  }

  Future<void> _editProduct(BuildContext context, Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    if (product.farmerId != farmerId) {
      messenger.showSnackBar(const SnackBar(content: Text('You can only edit your own products.')));
      return;
    }
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product, farmerId: farmerId)),
    );
    if (result != null) {
      if (result.farmerId != farmerId) {
        messenger.showSnackBar(const SnackBar(content: Text('You can only edit your own products.')));
        return;
      }
      onSave(_ownedProducts.map((p) => p.id == result.id ? result : p).toList());
      messenger.showSnackBar(const SnackBar(content: Text('Product updated')));
    }
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    if (product.farmerId != farmerId) {
      messenger.showSnackBar(const SnackBar(content: Text('You can only delete your own products.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Do you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onSave(_ownedProducts.where((p) => p.id != product.id).toList());
      messenger.showSnackBar(const SnackBar(content: Text('Product deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$farmerName\'s Dashboard'),
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProduct(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: _ownedProducts.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 56, color: Colors.black38),
                  SizedBox(height: 8),
                  Text('No products yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Tap "Add Product" to create one', style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: _ownedProducts.length,
              itemBuilder: (context, index) {
                final product = _ownedProducts[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lightGreen,
                      child: Icon(categoryIcon(product.category), color: forestGreen),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${product.farmer} • ${product.category}\n'
                      '${formatPrice(product.price)}/${product.unit} • Stock: ${product.stock}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit, color: forestGreen),
                          onPressed: () => _editProduct(context, product),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(context, product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Form page used for both adding and editing a product.
class ProductFormPage extends StatefulWidget {
  final Product? product; // null = add, not null = edit
  final String? farmerId;
  final String? farmerName;

  const ProductFormPage({super.key, this.product, this.farmerId, this.farmerName});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _farmerController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  late final TextEditingController _stockController;
  late String _category;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _farmerController = TextEditingController(text: p?.farmer ?? widget.farmerName ?? '');
    _priceController = TextEditingController(text: p == null ? '' : p.price.toString());
    _unitController = TextEditingController(text: p?.unit ?? 'kg');
    _stockController = TextEditingController(text: p == null ? '' : p.stock.toString());
    _category = p?.category ?? Product.categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmerController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _save() {
    // Runs every validator; only continues when all fields are valid.
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      farmer: _farmerController.text.trim(),
      farmerId: widget.product?.farmerId ?? widget.farmerId,
      category: _category,
      price: double.parse(_priceController.text.trim()),
      unit: _unitController.text.trim(),
      stock: int.parse(_stockController.text.trim()),
    );
    Navigator.pop(context, product);
  }

  InputDecoration _decoration(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: _decoration('Product name'),
              validator: (v) => Validators.required(v, 'Product name'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _farmerController,
              decoration: _decoration('Farmer name'),
              validator: (v) => Validators.required(v, 'Farmer name'),
              readOnly: widget.farmerId != null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: _decoration('Category'),
              items: Product.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('Price', prefix: '₹ '),
              validator: Validators.price,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _unitController,
              decoration: _decoration('Unit (kg, dozen, ...)'),
              validator: (v) => Validators.required(v, 'Unit'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Stock'),
              validator: Validators.stock,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_isEditing ? 'Save Changes' : 'Add Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
