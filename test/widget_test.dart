import 'package:farmdirect/main.dart';
import 'package:farmdirect/models/account.dart';
import 'package:farmdirect/models/product.dart';
import 'package:farmdirect/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Registration validates fields and opens customer marketplace',
      (tester) async {
    await tester.pumpWidget(const FarmDirectApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('New to FarmDirect? Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Password must contain at least 6 characters'),
        findsOneWidget);
    expect(find.text('Confirm password is required'), findsOneWidget);
    expect(find.text('Select a role'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Customer One');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await _selectRole(tester, AccountRole.customer);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await _register(tester, name: 'Customer One', role: AccountRole.customer);
    final storedAccounts =
        (await SharedPreferences.getInstance()).getString('accounts')!;
    expect(storedAccounts, contains('passwordHash'));
    expect(storedAccounts, isNot(contains('secret1')));
    expect(find.text('Hello, Customer One'), findsOneWidget);
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('₹40/kg'), findsOneWidget);
    expect(find.text('Manage'), findsNothing);
  });

  testWidgets(
      'Customer can add to cart and account session survives app restart',
      (tester) async {
    await tester.pumpWidget(const FarmDirectApp());
    await tester.pumpAndSettle();
    await _register(tester, name: 'Shopper', role: AccountRole.customer);

    await tester.tap(find.text('Add to Cart').first);
    await tester.pump();
    expect(find.text('Tomatoes added to cart'), findsOneWidget);

    await tester
        .pumpWidget(const FarmDirectApp(key: ValueKey('restarted-app')));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Shopper'), findsOneWidget);
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('₹40.00'), findsWidgets);
  });

  testWidgets(
      'Invalid login displays an error and logout preserves saved catalogue',
      (tester) async {
    await tester.pumpWidget(const FarmDirectApp());
    await tester.pumpAndSettle();
    await _register(tester, name: 'Returning User', role: AccountRole.customer);
    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();

    await _login(tester,
        name: 'Returning User',
        password: 'wrongpass',
        role: AccountRole.customer);
    expect(find.text('Invalid name, password, or role.'), findsOneWidget);

    await _login(tester,
        name: 'Returning User',
        password: 'secret1',
        role: AccountRole.customer);
    expect(find.text('Tomatoes'), findsOneWidget);
  });

  testWidgets(
      'Farmer listings are owned, editable, and hidden from another farmer',
      (tester) async {
    await tester.pumpWidget(const FarmDirectApp());
    await tester.pumpAndSettle();
    await _register(tester, name: 'Farmer One', role: AccountRole.farmer);
    expect(find.text('Farmer One\'s Dashboard'), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);

    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'My Apples');
    await tester.enterText(find.byType(TextFormField).at(2), '123.5');
    await tester.enterText(find.byType(TextFormField).at(4), '8');
    await tester.tap(find.widgetWithText(FilledButton, 'Add Product'));
    await tester.pumpAndSettle();
    expect(find.text('My Apples'), findsOneWidget);
    expect(find.textContaining('₹123.50/kg'), findsOneWidget);
    expect(find.textContaining('Stock: 8'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '150');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('₹150/kg'), findsOneWidget);
    expect(find.textContaining('Stock: 8'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete product?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('My Apples'), findsNothing);
    expect(find.text('No products yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    await _register(tester, name: 'Farmer Two', role: AccountRole.farmer);
    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('My Apples'), findsNothing);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    await _register(tester,
        name: 'Marketplace Customer', role: AccountRole.customer);
    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('My Apples'), findsNothing);
  });

  test('Legacy product records without a farmer ID remain readable', () {
    final product = Product.fromJson({
      'id': 'legacy',
      'name': 'Legacy Rice',
      'farmer': 'Old Farmer',
      'category': 'Grains',
      'price': 65,
      'unit': 'kg',
      'stock': 10,
    });
    expect(product.farmerId, isNull);
    expect(product.toJson()['farmerId'], isNull);
  });

  group('Validators and cart calculations', () {
    const tomatoes = Product(
      id: 'a',
      name: 'Tomatoes',
      farmer: 'F',
      category: 'Vegetables',
      price: 40,
      unit: 'kg',
      stock: 10,
    );
    const rice = Product(
      id: 'b',
      name: 'Rice',
      farmer: 'F',
      category: 'Grains',
      price: 65,
      unit: 'kg',
      stock: 5,
    );

    test('required field', () {
      expect(Validators.required('', 'Name'), isNotNull);
      expect(Validators.required('  ', 'Name'), isNotNull);
      expect(Validators.required('Rice', 'Name'), isNull);
    });

    test('price and stock validation', () {
      expect(Validators.price(''), isNotNull);
      expect(Validators.price('abc'), isNotNull);
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('-5'), isNotNull);
      expect(Validators.price('40.50'), isNull);
      expect(Validators.stock('2.5'), isNotNull);
      expect(Validators.stock('-1'), isNotNull);
      expect(Validators.stock('0'), isNull);
    });

    test('totals, stock-limited cart, currency, and order number', () {
      final cart = [
        CartItem(productId: 'a', quantity: 2),
        CartItem(productId: 'b', quantity: 1)
      ];
      expect(calculateTotal([tomatoes, rice], cart), 145);
      final cleaned =
          cleanCart([tomatoes, rice], [CartItem(productId: 'b', quantity: 9)]);
      expect(cleaned.single.quantity, 5);
      expect(formatRupees(125000), '₹1,25,000.00');
      expect(formatPrice(40.5), '₹40.50');
      expect(generateOrderNumber(DateTime.fromMillisecondsSinceEpoch(1234567)),
          'FD-234567');
    });
  });
}

Future<void> _register(
  WidgetTester tester, {
  required String name,
  required AccountRole role,
}) async {
  if (find.text('New to FarmDirect? Register').evaluate().isNotEmpty) {
    await tester.tap(find.text('New to FarmDirect? Register'));
    await tester.pumpAndSettle();
  }
  await tester.enterText(find.byType(TextFormField).at(0), name);
  await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
  await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
  await _selectRole(tester, role);
  await tester.tap(find.text('Create Account'));
  await tester.pumpAndSettle();
}

Future<void> _login(
  WidgetTester tester, {
  required String name,
  required String password,
  required AccountRole role,
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), name);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await _selectRole(tester, role);
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
}

Future<void> _selectRole(WidgetTester tester, AccountRole role) async {
  await tester.tap(find.byType(DropdownButtonFormField<AccountRole>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role.label).last);
  await tester.pumpAndSettle();
}
