import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/iuran_provider.dart';
import '../../widgets/status_badge.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }
          final paymentsAsync = ref.watch(myPaymentsProvider(profile.id));

          return paymentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (payments) {
              if (payments.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 12),
                      Text('Belum ada riwayat pembayaran',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }

              final fmt = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              );
              final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = payments[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _statusColor(p.status, p.notes)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            p.isLunas
                                ? Icons.check_circle
                                : Icons.pending_outlined,
                            color: _statusColor(p.status, p.notes),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.iuranTitle ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                fmt.format(p.iuranAmount ?? 0),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                              ),
                              if (p.paidAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Dibayar: ${dateFmt.format(p.paidAt!)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        StatusBadge(status: p.status, notes: p.notes),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status, String? notes) {
    if (notes == 'menunggu_konfirmasi') return AppTheme.accentColor;
    if (status == 'lunas') return AppTheme.successColor;
    if (status == 'terlambat') return AppTheme.errorColor;
    return AppTheme.textSecondary;
  }
}
