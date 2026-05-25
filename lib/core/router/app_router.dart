import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/role_constants.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/shared/app_shell.dart';
import '../../screens/shared/profile_screen.dart';
import '../../screens/siswa/home_screen.dart';
import '../../screens/siswa/payment_screen.dart';
import '../../screens/siswa/qris_screen.dart';
import '../../screens/siswa/history_screen.dart';
import '../../screens/siswa/money_screen.dart';
import '../../screens/siswa/request_fund_screen.dart';
import '../../screens/bendahara/home_screen.dart';
import '../../screens/bendahara/verifikasi_screen.dart';
import '../../screens/bendahara/iuran_screen.dart';
import '../../screens/bendahara/buat_iuran_screen.dart';
import '../../screens/bendahara/kas_screen.dart';
import '../../screens/bendahara/catat_transaksi_screen.dart';
import '../../screens/bendahara/daftar_siswa_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);
  final profileService = ref.watch(profileServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isBendaharaRoute = state.matchedLocation.startsWith('/bendahara');

      if (session == null) {
        if (!isAuthRoute) {
          return '/login';
        }
        return null;
      }

      final role = await profileService.getMyRole();
      final homeRoute = isTreasurerRole(role) ? '/bendahara/home' : '/home';

      if (isAuthRoute) {
        return homeRoute;
      }

      if (isBendaharaRoute && !isTreasurerRole(role)) {
        return '/home';
      }

      if (state.matchedLocation == '/') {
        return homeRoute;
      }

      if (role == null && !isAuthRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const SiswaHomeScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/money',
            builder: (context, state) => const MoneyScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/bendahara/home',
            builder: (context, state) => const BendaharaHomeScreen(),
          ),
          GoRoute(
            path: '/bendahara/iuran',
            builder: (context, state) => const BendaharaIuranScreen(),
          ),
          GoRoute(
            path: '/bendahara/kas',
            builder: (context, state) => const BendaharaKasScreen(),
          ),
          GoRoute(
            path: '/bendahara/verifikasi',
            builder: (context, state) => const VerifikasiScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/payment/qris',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QrisScreen(
            iuranId: extra['iuranId'] as String? ?? '',
            amount: extra['amount'] as int? ?? 0,
            title: extra['title'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/request-fund',
        builder: (context, state) => const RequestFundScreen(),
      ),

      GoRoute(
        path: '/bendahara/buat-iuran',
        builder: (context, state) => const BuatIuranScreen(),
      ),
      GoRoute(
        path: '/bendahara/transaksi',
        builder: (context, state) => const CatatTransaksiScreen(),
      ),
      GoRoute(
        path: '/bendahara/siswa',
        builder: (context, state) => const DaftarSiswaScreen(),
      ),

    ],
  );
});
