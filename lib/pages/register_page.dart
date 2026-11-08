import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/messages.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String _role = 'seeker';
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final AuthResponse response = await AuthService.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _role,
      );

      if (!mounted) return;

      if (response.session != null) {
        // "Confirm email" nonaktif: pengguna langsung memiliki session.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomePage()),
          (route) => false,
        );
        return;
      }

      // "Confirm email" aktif: akun dibuat, tetapi belum memiliki session.
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Registrasi berhasil'),
          content: const Text(
            'Akun sudah dibuat. Silakan cek email untuk konfirmasi, '
            'kemudian masuk ke aplikasi.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyAuthMessage(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Buat akun baru',
      subtitle: 'Pilih peranmu: pencari kos untuk mencari, atau pemilik kos untuk memasarkan properti.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Sudah punya akun?',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Masuk'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'Minimal 6 karakter',
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
                if (value.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi password',
                prefixIcon: Icon(Icons.lock_reset, size: 20),
              ),
              validator: (String? value) {
                if (value != _passwordController.text) {
                  return 'Konfirmasi password tidak sama';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Daftar sebagai',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'seeker',
                  child: Text('Pencari kos'),
                ),
                DropdownMenuItem<String>(
                  value: 'owner',
                  child: Text('Pemilik kos'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) setState(() => _role = value);
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Daftar sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
