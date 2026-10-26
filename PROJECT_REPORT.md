# FarmDirect — Mini-Project Report

## 1. Introduction
FarmDirect is a simple Flutter application that demonstrates an agricultural marketplace with local Customer and Farmer accounts. Customers can view sample produce, search and filter products, maintain a cart, and simulate placing an order. Farmers can manage their own listings.

## 2. Objectives
- Build a mobile interface with Flutter and Dart.
- Demonstrate widgets, navigation, forms, validation, state updates, and responsive layout.
- Implement product CRUD operations.
- Add local role-based registration, login, and logout.
- Restrict product changes to the owning Farmer account.
- Persist products and cart items locally.
- Display all prices in Indian Rupees (₹).

## 3. Modules
1. **Authentication:** Local Customer/Farmer accounts, role selection, and persistent sessions.
2. **Home:** Customer product grid, search, category filters, and add-to-cart action.
3. **Manage Products:** Farmer-only add, edit, and delete operations for owned listings.
4. **Cart:** Customer quantity controls, stock checks, totals, and demo order confirmation.
5. **Local storage:** Save account hashes, session, product catalogue, and cart data between launches.

## 4. Tools and technologies
- Flutter and Dart
- Material 3
- `shared_preferences`
- `cryptography` (PBKDF2-HMAC-SHA256 password hashing)
- Flutter test framework

## 5. Design
The UI uses a forest-green and white theme, reusable product cards, category icons, and responsive grid columns. Produce illustrations use built-in icons, so the app does not depend on remote image services.

## 6. Data flow
The main app state holds the active account, product list, and cart. `StorageService` loads product/cart JSON and `AuthService` maintains accounts and the session. Product prices remain numeric; farmer listings record their owning account ID, while legacy records without an owner remain in the catalogue. Cart totals are calculated from numeric prices and quantities. When a demo order is placed, the app decreases product stock, clears the cart, and displays a generated order number.

## 7. Limitations
This project is intended for academic demonstration. Authentication is local only: passwords are salted and hashed, but preferences are not a secure production account store. There is no server, real payment gateway, delivery integration, order-history module, or cross-device synchronization.

## 8. Conclusion
FarmDirect provides a small, understandable example of a Flutter marketplace while demonstrating core Flutter lab concepts.
