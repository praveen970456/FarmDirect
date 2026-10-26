import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';

class AuthService {
  static const String _accountsKey = 'accounts';
  static const String _activeAccountKey = 'activeAccountId';
  static const int _saltLength = 16;

  final Pbkdf2 _passwordHasher = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );

  Future<Account?> loadSession() async {
    final preferences = await SharedPreferences.getInstance();
    final accountId = preferences.getString(_activeAccountKey);
    if (accountId == null) return null;

    final accounts = await _loadAccounts(preferences);
    for (final account in accounts) {
      if (account.id == accountId) return account;
    }

    await preferences.remove(_activeAccountKey);
    return null;
  }

  Future<Account> register({
    required String name,
    required String password,
    required AccountRole role,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(preferences);
    final normalizedName = name.trim();
    if (accounts.any((account) =>
        account.name.toLowerCase() == normalizedName.toLowerCase())) {
      throw const AuthException('An account with this name already exists.');
    }

    final random = Random.secure();
    final salt = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    final hash = await _hashPassword(password, salt);
    final account = Account(
      id: '${DateTime.now().microsecondsSinceEpoch}-${base64UrlEncode(salt)}',
      name: normalizedName,
      role: role,
      passwordSalt: base64Encode(salt),
      passwordHash: base64Encode(hash),
    );
    accounts.add(account);
    await _saveAccounts(preferences, accounts);
    await _saveSession(preferences, account);
    return account;
  }

  Future<Account> login({
    required String name,
    required String password,
    required AccountRole role,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(preferences);
    for (final account in accounts) {
      if (account.name.toLowerCase() != name.trim().toLowerCase() ||
          account.role != role) {
        continue;
      }
      final salt = base64Decode(account.passwordSalt);
      final expectedHash = base64Decode(account.passwordHash);
      final actualHash = await _hashPassword(password, salt);
      if (_constantTimeEquals(actualHash, expectedHash)) {
        await _saveSession(preferences, account);
        return account;
      }
      break;
    }
    throw const AuthException('Invalid name, password, or role.');
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeAccountKey);
  }

  Future<List<int>> _hashPassword(String password, List<int> salt) async {
    final key = await _passwordHasher.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
  }

  bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }

  Future<List<Account>> _loadAccounts(SharedPreferences preferences) async {
    final text = preferences.getString(_accountsKey);
    if (text == null) return [];
    try {
      final decoded = jsonDecode(text) as List<dynamic>;
      return decoded
          .map((entry) => Account.fromJson(entry as Map<String, dynamic>))
          .toList();
    } on Object {
      throw const AuthException('Saved account data could not be read.');
    }
  }

  Future<void> _saveAccounts(
      SharedPreferences preferences, List<Account> accounts) async {
    final saved = await preferences.setString(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
    if (!saved) {
      throw const AuthException('Could not save account data on this device.');
    }
  }

  Future<void> _saveSession(
      SharedPreferences preferences, Account account) async {
    final saved = await preferences.setString(_activeAccountKey, account.id);
    if (!saved) throw const AuthException('Could not save your login session.');
  }
}
