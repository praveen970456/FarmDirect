import 'package:flutter/material.dart';

import '../models/account.dart';
import '../theme/app_colors.dart';

typedef AuthAction = Future<void> Function(String name, String password, AccountRole role);

class AuthScreen extends StatefulWidget {
  final AuthAction onLogin;
  final AuthAction onRegister;

  const AuthScreen({super.key, required this.onLogin, required this.onRegister});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AccountRole? _role;
  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final role = _role;
    if (role == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final action = _registering ? widget.onRegister : widget.onLogin;
      await action(_nameController.text.trim(), _passwordController.text, role);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Password must contain at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.agriculture, color: forestGreen, size: 56),
                    const SizedBox(height: 8),
                    const Text(
                      'FarmDirect',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: forestGreen),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _registering ? 'Create your account' : 'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration('Name', Icons.person_outline),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _decoration('Password', Icons.lock_outline),
                      validator: _validatePassword,
                    ),
                    if (_registering) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: _decoration('Confirm password', Icons.lock_reset),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Confirm password is required';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<AccountRole>(
                      initialValue: _role,
                      isExpanded: true,
                      decoration: _decoration('Role', Icons.badge_outlined),
                      hint: const Text('Select role'),
                      items: AccountRole.values
                          .map((role) => DropdownMenuItem(value: role, child: Text(role.label)))
                          .toList(),
                      onChanged: _busy ? null : (role) => setState(() => _role = role),
                      validator: (role) => role == null ? 'Select a role' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_registering ? 'Create Account' : 'Login'),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _registering = !_registering;
                                _error = null;
                                _formKey.currentState?.reset();
                              }),
                      child: Text(
                        _registering ? 'Already registered? Login' : 'New to FarmDirect? Register',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Offline demo only. Accounts are stored on this device; this is not production-grade authentication.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}
