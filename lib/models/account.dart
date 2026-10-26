enum AccountRole { customer, farmer }

extension AccountRoleLabel on AccountRole {
  String get label => switch (this) {
        AccountRole.customer => 'Customer',
        AccountRole.farmer => 'Farmer',
      };
}

class Account {
  final String id;
  final String name;
  final AccountRole role;
  final String passwordSalt;
  final String passwordHash;

  const Account({
    required this.id,
    required this.name,
    required this.role,
    required this.passwordSalt,
    required this.passwordHash,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'passwordSalt': passwordSalt,
        'passwordHash': passwordHash,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        role: AccountRole.values.byName(json['role'] as String),
        passwordSalt: json['passwordSalt'] as String,
        passwordHash: json['passwordHash'] as String,
      );
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}
