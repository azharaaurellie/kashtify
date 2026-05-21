import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/role_constants.dart';
import '../../providers/auth_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _selectedIndex(String location, bool isBendahara) {
    if (isBendahara) {
      if (location.startsWith('/bendahara/iuran')) return 1;
      if (location.startsWith('/bendahara/kas')) return 2;
      if (location.startsWith('/bendahara/verifikasi')) return 3;
      if (location.startsWith('/profile')) return 4;
      return 0;
    }

    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/money')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, bool isBendahara, int index) {
    if (isBendahara) {
      switch (index) {
        case 0:
          context.go('/bendahara/home');
          break;
        case 1:
          context.go('/bendahara/iuran');
          break;
        case 2:
          context.go('/bendahara/kas');
          break;
        case 3:
          context.go('/bendahara/verifikasi');
          break;
        case 4:
          context.go('/profile');
          break;
      }
      return;
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/money');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final role = ref.watch(myRoleProvider).valueOrNull;
    final isBendahara = isTreasurerRole(role);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(location, isBendahara),
        onTap: (index) => _onTap(context, isBendahara, index),
        type: BottomNavigationBarType.fixed,
        items: isBendahara
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Tagihan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_outlined),
                  activeIcon: Icon(Icons.account_balance),
                  label: 'Kas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fact_check_outlined),
                  activeIcon: Icon(Icons.fact_check),
                  label: 'Verifikasi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outlined),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_outlined),
                  activeIcon: Icon(Icons.account_balance),
                  label: 'Kas Kelas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outlined),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
      ),
    );
  }
}
