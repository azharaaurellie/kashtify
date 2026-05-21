import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/iuran_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/status_badge.dart';

class DaftarSiswaScreen extends ConsumerWidget {
  const DaftarSiswaScreen({super.key});

  void _showDetailBottomSheet(
      BuildContext context, String siswaId, String siswaName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _SiswaDetailSheet(siswaId: siswaId, siswaName: siswaName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siswaAsync = ref.watch(siswaSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Rekap Siswa')),
      body: siswaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listData) {
          if (listData.isEmpty) {
            return const Center(child: Text('Belum ada data siswa'));
          }

          final fmt = NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: listData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = listData[i];
              final hasTunggakan = s.belumLunas > 0;
              return InkWell(
                onTap: () =>
                    _showDetailBottomSheet(context, s.siswaId, s.fullName),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          s.fullName.isNotEmpty
                              ? s.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('NIS: ${s.nis ?? "-"}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasTunggakan
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hasTunggakan
                                  ? '${s.belumLunas} Tagihan'
                                  : 'Lunas',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fmt.format(s.totalTunggakan),
                            style: TextStyle(
                              color: hasTunggakan
                                  ? AppTheme.errorColor
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SiswaDetailSheet extends StatefulWidget {
  final String siswaId;
  final String siswaName;

  const _SiswaDetailSheet({required this.siswaId, required this.siswaName});

  @override
  State<_SiswaDetailSheet> createState() => _SiswaDetailSheetState();
}

class _SiswaDetailSheetState extends State<_SiswaDetailSheet> {
  final _service = ProfileService();
  List<Map<String, dynamic>>? _payments;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getSiswaPaymentDetail(widget.siswaId);
    if (mounted) setState(() => _payments = data);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('Detail Iuran: ${widget.siswaName}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          Expanded(
            child: _payments == null
                ? const Center(child: CircularProgressIndicator())
                : _payments!.isEmpty
                    ? const Center(child: Text('Tidak ada data iuran'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments!.length,
                        itemBuilder: (ctx, i) {
                          final p = _payments![i];
                          final iuran = p['iuran'];
                          final fmt = NumberFormat.currency(
                              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppTheme.dividerColor)),
                            child: ListTile(
                              title: Text(iuran['title']),
                              subtitle: Text(fmt.format(iuran['amount'])),
                              trailing: StatusBadge(
                                  status: p['status'], notes: p['notes']),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
