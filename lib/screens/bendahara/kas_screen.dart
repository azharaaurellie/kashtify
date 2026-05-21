import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/kas_provider.dart';
import '../../widgets/kas_summary_card.dart';

class BendaharaKasScreen extends ConsumerStatefulWidget {
  const BendaharaKasScreen({super.key});

  @override
  ConsumerState<BendaharaKasScreen> createState() => _BendaharaKasScreenState();
}

class _BendaharaKasScreenState extends ConsumerState<BendaharaKasScreen> {
  String _filter = 'semua'; // 'semua' | 'pemasukan' | 'pengeluaran'

  @override
  Widget build(BuildContext context) {
    final kasSummaryAsync = ref.watch(kasSummaryProvider);
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buku Kas Kelas')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                kasSummaryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (summary) => KasSummaryCard(summary: summary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Riwayat Transaksi',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _filter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'semua', child: Text('Semua')),
                        DropdownMenuItem(
                            value: 'pemasukan', child: Text('Pemasukan')),
                        DropdownMenuItem(
                            value: 'pengeluaran', child: Text('Pengeluaran')),
                      ],
                      onChanged: (v) => setState(() => _filter = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          txAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            data: (transactions) {
              var filtered = transactions;
              if (_filter != 'semua') {
                filtered =
                    transactions.where((t) => t.type == _filter).toList();
              }

              if (filtered.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Tidak ada transaksi',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                );
              }

              final fmt = NumberFormat.currency(
                  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
              final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final t = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: t.isPemasukan
                                    ? AppTheme.successColor.withValues(alpha: 0.1)
                                    : AppTheme.errorColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                t.isPemasukan
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: t.isPemasukan
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.description,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${dateFmt.format(t.date)} • Oleh: ${t.profileFullName ?? "-"}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '${t.isPemasukan ? '+' : '-'}${fmt.format(t.amount)}',
                              style: TextStyle(
                                  color: t.isPemasukan
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bendahara/transaksi'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
