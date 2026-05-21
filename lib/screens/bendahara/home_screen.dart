import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fund_request_provider.dart';
import '../../providers/kas_provider.dart';
import '../../providers/iuran_provider.dart';
import '../../widgets/kas_summary_card.dart';

class BendaharaHomeScreen extends ConsumerWidget {
  const BendaharaHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final kasSummaryAsync = ref.watch(kasSummaryProvider);
    final pendingAsync = ref.watch(pendingVerifikasiProvider);
    final pendingFundAsync = ref.watch(pendingFundRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 130,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Halo, ${profile.fullName.split(' ').first} \u{1F451}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Bendahara Kelas',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    kasSummaryAsync.when(
                      loading: () => const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (summary) => KasSummaryCard(summary: summary),
                    ),
                    const SizedBox(height: 24),

                    // Verifikasi Card
                    pendingAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (pendingPayments) {
                        final pendingFunds =
                            pendingFundAsync.valueOrNull?.length ?? 0;
                        final totalPending =
                            pendingPayments.length + pendingFunds;
                        return GestureDetector(
                          onTap: () => context.push('/bendahara/verifikasi'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: totalPending > 0
                                  ? AppTheme.accentColor.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: totalPending > 0
                                    ? AppTheme.accentColor
                                    : AppTheme.dividerColor,
                                width: totalPending > 0 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: totalPending > 0
                                        ? AppTheme.accentColor
                                        : AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.verified_user_outlined,
                                    color: totalPending > 0
                                        ? Colors.white
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Verifikasi Pengajuan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        totalPending > 0
                                            ? '$totalPending butuh verifikasi'
                                            : 'Tidak ada permintaan tertunda',
                                        style: TextStyle(
                                          color: totalPending > 0
                                              ? AppTheme.warningColor
                                              : AppTheme.textSecondary,
                                          fontSize: 13,
                                          fontWeight: totalPending > 0
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Tindakan Cepat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.post_add,
                            label: 'Buat Tagihan',
                            color: const Color(0xFF4299E1),
                            onTap: () => context.push('/bendahara/buat-iuran'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.qr_code_2,
                            label: 'Atur QRIS',
                            color: const Color(0xFF48BB78),
                            onTap: () => context.push('/bendahara/qris'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ActionCard(
                      icon: Icons.add_card,
                      label: 'Catat Transaksi',
                      color: const Color(0xFFED8936),
                      isHorizontal: true,
                      onTap: () => context.push('/bendahara/transaksi'),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.people_outline,
                      label: 'Daftar Siswa & Tunggakan',
                      color: const Color(0xFF9F7AEA),
                      isHorizontal: true,
                      onTap: () => context.push('/bendahara/siswa'),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isHorizontal;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isHorizontal
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.textSecondary),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
