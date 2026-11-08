import 'package:flutter/material.dart';

/// Menampilkan [child] hanya jika [role] termasuk dalam [allowed].
///
/// Ini pengaman tampilan. Aturan sebenarnya tetap ditegakkan oleh RLS pada
/// database, karena UI dapat dilewati oleh pengguna yang memanggil API langsung.
class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.role,
    required this.allowed,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final String role;
  final List<String> allowed;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return allowed.contains(role) ? child : fallback;
  }
}
