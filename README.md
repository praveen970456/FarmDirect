# FarmDirect — Fresh from Farmers

FarmDirect is a small, offline-first Flutter agricultural marketplace mini-project. It includes local Customer and Farmer accounts, a product catalogue, search and category filters, farmer-owned product management, a shopping cart, Indian Rupee price calculations, and simulated order confirmation.

**Currency:** Indian Rupees (₹) only.

## Features

- Home screen with 8 sample products, search, and category filters.
- Customer and Farmer registration/login with role-specific screens and logout.
- Farmer dashboard with add, edit, and delete operations restricted to the logged-in farmer's own products.
- Cart with quantity controls, stock checks, and automatic totals.
- Demo order confirmation with a generated order number.
- Accounts, active session, products, and cart saved locally using `shared_preferences`.
- Green-and-white Material 3 design that works offline.

Authentication is a local demonstration only. Passwords are stored as salted PBKDF2-HMAC-SHA256 hashes, but device-local preferences are not a secure production account store and can be modified by someone with device access. There is no backend, online payment, delivery service, or order-history screen. Orders are demonstrations only.

## Run on Windows / VS Code

Install the Flutter SDK and Android Studio (or another Android SDK setup), then open this project folder in VS Code.

The supplied archive contains the application source and tests. Flutter's generated platform folders are not included, so run these commands from the project root **once** to generate Android runner files:

```bash
flutter create --platforms=android --project-name farmdirect .
flutter pub get
flutter analyze
flutter test
flutter run
```

If `flutter create` reports that the project already exists, run it from the project root as shown above; it should add the missing platform scaffolding while retaining the existing source files. If you want to run on a connected phone, enable Developer Options and USB debugging first. You can also select an Android emulator in VS Code.

## Project structure

```text
lib/
  main.dart
  models/
    account.dart
    product.dart
  screens/
    auth_screen.dart
    home_screen.dart
    manage_products_screen.dart
    cart_screen.dart
  services/
    auth_service.dart
    storage_service.dart
  theme/app_colors.dart
  utils/currency_formatter.dart
  widgets/product_card.dart
test/
  widget_test.dart
```

## Data and currency

Sample products are created only when no catalogue has been saved. Product prices are stored as numeric values and formatted for display in INR. Farmer-owned listings store the owning account ID; older product records without this field remain available in the marketplace but are not assigned to a farmer account. Cart totals are calculated from the actual product price and quantity. Product, cart, account hashes, and the active login session persist locally on the device. Logging out removes only the active session.

## Syllabus mapping

| # | Flutter lab concept | Demonstrated in |
|---|---|---|
| 1 | Dart variables, functions, lists, conditions | `lib/models/product.dart` |
| 2 | Text, Container, Row, Column, Stack, ListView, GridView | Screen and product card widgets |
| 3 | Responsive UI | `lib/screens/home_screen.dart` (`LayoutBuilder`, `MediaQuery`) |
| 4 | Navigation | Bottom `NavigationBar` and product form route |
| 5 | StatefulWidget, StatelessWidget, `setState` | `main.dart`, `home_screen.dart`, `cart_screen.dart` |
| 6 | Reusable widgets and themes | `product_card.dart`, `theme/app_colors.dart` |
| 7 | Forms and validation | `ProductFormPage` and `Validators` |
| 8 | UI feedback and dialogs | SnackBars and confirmation dialogs |
| 9 | Loading and displaying local data | `StorageService` and `MainShell` |
| 10 | Unit/widget testing | `test/widget_test.dart` |
| 11 | Local storage initialization | `lib/services/storage_service.dart` |
| 12 | Create, read, update, delete products | `lib/screens/manage_products_screen.dart` |
| 13 | Role-based local authentication | `lib/screens/auth_screen.dart`, `lib/services/auth_service.dart` |

## Short project report

**Aim:** Develop a simple role-based Flutter marketplace where Customers browse and order products and Farmers manage their own listings.

**Modules:** Registration and login, Customer marketplace and cart, Farmer-owned product management, local storage, currency formatting, and demo order confirmation.

**Implementation:** `MainShell` owns the active role and shared product/cart state. `StorageService` persists catalogue/cart data, while `AuthService` stores salted PBKDF2-HMAC-SHA256 password hashes and the active session in `shared_preferences`. Farmer-owned products are identified by account ID. Legacy products without an owner remain available to Customers.

**Limitations:** This is a local college demonstration, not production-grade authentication. Data is stored on the current device, with no backend, real transactions, delivery tracking, or multi-device synchronization.

## Viva questions and short answers

1. **What is Flutter?** A UI toolkit for building applications from a Dart codebase.
2. **What is Dart?** The programming language used to develop Flutter applications.
3. **What is a widget?** A building block of Flutter's user interface.
4. **StatefulWidget vs StatelessWidget?** A StatefulWidget manages changing state; a StatelessWidget represents UI without its own mutable state.
5. **What does `setState` do?** It tells Flutter to rebuild the widget after state changes.
6. **What is `shared_preferences`?** A local key-value storage package suitable for small settings and simple saved data.
7. **How are products saved?** The product list is encoded as JSON and saved locally.
8. **What is CRUD?** Create, Read, Update, and Delete operations.
9. **How is form validation performed?** Validators check user input before a product is saved.
10. **How is the cart total calculated?** Each product price is multiplied by its quantity and the results are added.
11. **Why store prices as numbers?** Numeric values support correct calculations; formatting is applied only for display.
12. **What is `LayoutBuilder`?** A widget that lets the UI adapt to the available layout constraints.
13. **What is `MediaQuery`?** It provides information about the screen and device environment.
14. **What is a demo order?** A simulated order used for demonstration; it does not charge money or arrange delivery.
15. **Does FarmDirect require internet?** No, the app's core features use local data.
