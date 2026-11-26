import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/database_helper.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<String> onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _database = DatabaseHelper.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final prefs = await SharedPreferences.getInstance();
      final email = _emailController.text.trim().toLowerCase();
      final passwordHash = _hashPassword(_passwordController.text);

      if (_isRegister) {
        final name = _nameController.text.trim();
        await _database.insertAccount(
          name: name,
          email: email,
          passwordHash: passwordHash,
        );
        await prefs.setString('userName', name);
        await prefs.setBool('isLoggedIn', true);
        if (!mounted) return;
        widget.onLoginSuccess(name);
        return;
      }

      final account = await _database.getAccountByEmail(email);
      if (account != null && account['passwordHash'] == passwordHash) {
        final name = account['name'] as String;
        await prefs.setString('userName', name);
        await prefs.setBool('isLoggedIn', true);
        if (!mounted) return;
        widget.onLoginSuccess(name);
        return;
      }

      final legacyEmail = prefs.getString('accountEmail')?.toLowerCase();
      final legacyPasswordHash = prefs.getString('accountPasswordHash');
      if (account == null &&
          legacyEmail == email &&
          legacyPasswordHash == passwordHash) {
        final name =
            prefs.getString('accountName') ??
            prefs.getString('userName') ??
            'Pengguna';
        await _database.insertAccount(
          name: name,
          email: email,
          passwordHash: passwordHash,
        );
        await prefs.remove('accountName');
        await prefs.remove('accountEmail');
        await prefs.remove('accountPasswordHash');
        await prefs.setString('userName', name);
        await prefs.setBool('isLoggedIn', true);
        if (!mounted) return;
        widget.onLoginSuccess(name);
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email atau kata sandi tidak sesuai'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DatabaseException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = error.isUniqueConstraintError()
          ? 'Email ini sudah terdaftar'
          : 'Tidak dapat menyimpan atau membaca akun: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat login: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.78),
              const Color(0xFF0B5F45),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 820 : 440),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(child: _buildBrand(context)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildForm(context)),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildBrand(context),
                            const SizedBox(height: 18),
                            _buildForm(context),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 290),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.mosque_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'SholatKu',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Catat jadwal, kehadiran, dan\nkemajuan ibadahmu setiap hari.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isRegister ? 'Buat akun baru' : 'Selamat datang',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _isRegister
                ? 'Lengkapi data untuk mulai menggunakan SholatKu.'
                : 'Masuk untuk melanjutkan aktivitas ibadah.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isRegister
                ? Padding(
                    key: const ValueKey('name'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama pengguna',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_isRegister &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-name')),
          ),
          TextFormField(
            key: const Key('login_email_field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            enableInteractiveSelection: true,
            readOnly: false,
            enabled: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Email tidak boleh kosong';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Masukkan email yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('login_password_field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            autofillHints: const [AutofillHints.password],
            autocorrect: false,
            enableSuggestions: false,
            enableInteractiveSelection: true,
            readOnly: false,
            enabled: true,
            decoration: InputDecoration(
              labelText: 'Kata sandi',
              helperText: 'Kata sandi disamarkan. Tekan ikon mata untuk melihat.',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Tampilkan' : 'Sembunyikan',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kata sandi tidak boleh kosong';
              }
              if (_isRegister && value.length < 6) {
                return 'Minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isRegister ? 'Daftar Sekarang' : 'Masuk'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isRegister = !_isRegister;
                      _formKey.currentState?.reset();
                    });
                  },
            child: Text(
              _isRegister
                  ? 'Sudah punya akun? Masuk'
                  : 'Belum punya akun? Daftar',
            ),
          ),
        ],
      ),
    );
  }
}
