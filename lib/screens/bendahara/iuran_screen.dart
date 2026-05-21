import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/iuran_provider.dart';

class BendaharaIuranScreen extends ConsumerWidget {
  const BendaharaIuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iuranAsync = ref.watch(iuranSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Tagihan')),
      body: iuranAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (iuranList) {
          if (iuranList.isEmpty) {
            return const Center(
              child: Text('Belum ada tagihan',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          final fmtAmount = NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          final fmtDate = DateFormat('d MMM yyyy', 'id_ID');

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: iuranList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final item = iuranList[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            fmtAmount.format(item.amount),
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Batas Waktu: ${fmtDate.format(item.dueDate)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          'Terkumpul: ${fmtAmount.format(item.totalTerkumpul)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Progress Pembayaran',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: item.progressPercent,
                        backgroundColor: AppTheme.dividerColor,
                        color: item.progressPercent == 1.0
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${item.sudahBayar} Siswa (${(item.progressPercent * 100).toStringAsFixed(0)}%) Lunas',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        Text('${item.belumBayar} Belum',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.errorColor)),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bendahara/buat-iuran'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
