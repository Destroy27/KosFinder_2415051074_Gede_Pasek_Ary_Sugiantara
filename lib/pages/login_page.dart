import 'package:flutter/material.dart';

import '../core/messages.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(friendlyAuthMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Masuk ke KosFinder',
      subtitle: 'Cari kos di sekitar kampus, atau kelola kos milikmu dari satu tempat.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Belum punya akun?',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RegisterPage(),
                    ),
                  ),
            child: const Text('Daftar'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@email.com',
                prefixIcon: Icon(Icons.alternate_email, size: 20),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!value.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_loading) _login();
              },
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Password wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}
