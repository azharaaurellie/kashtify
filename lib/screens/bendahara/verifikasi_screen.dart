import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/fund_request_model.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/fund_request_provider.dart';
import '../../providers/iuran_provider.dart';
import '../../providers/kas_provider.dart';

class VerifikasiScreen extends ConsumerWidget {
  const VerifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingVerifikasiProvider);
    final pendingFundAsync = ref.watch(pendingFundRequestsProvider);
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi')),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pendingPayments) {
          return pendingFundAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) {
              debugPrint('Error fetching fund requests: $e');
              return _buildContent(pendingPayments, [], fmt);
            },
            data: (pendingFunds) => _buildContent(pendingPayments, pendingFunds, fmt),
          );
        },
      ),
    );
  }

  Widget _buildContent(
      List<dynamic> pendingPayments, List<dynamic> pendingFunds, NumberFormat fmt) {
    if (pendingPayments.isEmpty && pendingFunds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 64, color: AppTheme.successColor),
            SizedBox(height: 16),
            Text(
              'Tidak ada verifikasi tertunda',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingPayments.isNotEmpty) ...[
          const Text(
            'Verifikasi Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...pendingPayments.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PaymentVerificationCard(payment: p, fmt: fmt),
            ),
          ),
        ],
        if (pendingPayments.isNotEmpty && pendingFunds.isNotEmpty)
          const SizedBox(height: 8),
        if (pendingFunds.isNotEmpty) ...[
          const Text(
            'Pengajuan Dana',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...pendingFunds.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FundRequestCard(request: request, fmt: fmt),
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentVerificationCard extends ConsumerWidget {
  final dynamic payment;
  final NumberFormat fmt;

  const _PaymentVerificationCard({
    required this.payment,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.siswaName ?? 'Siswa',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.iuranTitle ?? '-',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Menunggu',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            fmt.format(payment.iuranAmount ?? 0),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          if (payment.siswaNis != null && '${payment.siswaNis}'.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'NIS: ${payment.siswaNis}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (payment.paymentProofUrl != null) ...[
            GestureDetector(
              onTap: () => _showProofDialog(context, payment.paymentProofUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    payment.paymentProofUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ProofPlaceholder(
                      onTap: () =>
                          _showProofDialog(context, payment.paymentProofUrl!),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  _showProofDialog(context, payment.paymentProofUrl!),
              icon: const Icon(Icons.open_in_full),
              label: const Text('Lihat bukti pembayaran'),
            ),
          ] else
            const _ProofPlaceholder(),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showVerificationForm(context, payment, ref),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Cek & Verifikasi Pembayaran'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationForm(
      BuildContext context, dynamic payment, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _VerificationFormSheet(payment: payment, fmt: fmt, cardRef: ref),
      ),
    );
  }

  Future<void> _showProofDialog(BuildContext context, String proofUrl) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Bukti Pembayaran'),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  proofUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Bukti pembayaran tidak bisa dimuat.'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofPlaceholder extends StatelessWidget {
  final VoidCallback? onTap;

  const _ProofPlaceholder({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: AppTheme.textSecondary,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Bukti pembayaran tidak tersedia',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FundRequestCard extends ConsumerWidget {
  final FundRequestModel request;
  final NumberFormat fmt;

  const _FundRequestCard({
    required this.request,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.warningColor.withValues(alpha: 0.15),
                child: Text(
                  (request.requesterName ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'NIS: ${request.requesterNis ?? '-'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Text(
            request.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(request.amount),
            style: const TextStyle(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.reason,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      final bendaharaId =
                          Supabase.instance.client.auth.currentUser!.id;
                      await ref.read(fundRequestServiceProvider).rejectRequest(
                            requestId: request.id,
                            bendaharaId: bendaharaId,
                          );
                      ref.invalidate(pendingFundRequestsProvider);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal: $e')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final bendaharaId =
                          Supabase.instance.client.auth.currentUser!.id;
                      await ref.read(fundRequestServiceProvider).approveRequest(
                            requestId: request.id,
                            bendaharaId: bendaharaId,
                            requesterId: request.requestedBy,
                            title: request.title,
                            amount: request.amount,
                            reason: request.reason,
                          );
                      ref.invalidate(pendingFundRequestsProvider);
                      ref.invalidate(kasSummaryProvider);
                      ref.invalidate(transactionsProvider);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                  child: const Text('Setujui'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationFormSheet extends StatefulWidget {
  final dynamic payment;
  final NumberFormat fmt;
  final WidgetRef cardRef;

  const _VerificationFormSheet({
    required this.payment,
    required this.fmt,
    required this.cardRef,
  });

  @override
  State<_VerificationFormSheet> createState() => _VerificationFormSheetState();
}

class _VerificationFormSheetState extends State<_VerificationFormSheet> {
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _tolak() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan wajib diisi untuk penolakan')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.cardRef.read(iuranServiceProvider).tolakPembayaran(
            widget.payment.id,
            notes: _notesController.text.trim(),
          );
      widget.cardRef.invalidate(pendingVerifikasiProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menolak: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _terima() async {
    setState(() => _isLoading = true);
    try {
      final bendaharaId = Supabase.instance.client.auth.currentUser!.id;
      final notes = _notesController.text.trim();
      await widget.cardRef.read(iuranServiceProvider).konfirmasiLunas(
            paymentId: widget.payment.id,
            bendaharaId: bendaharaId,
            siswaId: widget.payment.siswaId,
            iuranTitle: widget.payment.iuranTitle ?? '-',
            amount: widget.payment.iuranAmount ?? 0,
            notes: notes.isNotEmpty ? notes : null,
          );
      widget.cardRef.invalidate(pendingVerifikasiProvider);
      widget.cardRef.invalidate(kasSummaryProvider);
      widget.cardRef.invalidate(transactionsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verifikasi Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.payment.paymentProofUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.payment.paymentProofUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Bukti pembayaran tidak bisa dimuat.'),
                ),
              ),
            )
          else
            const _ProofPlaceholder(),
          const SizedBox(height: 20),
          Text(
            'Siswa: ${widget.payment.siswaName ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text('Iuran: ${widget.payment.iuranTitle ?? '-'}'),
          Text(
            'Nominal: ${widget.fmt.format(widget.payment.iuranAmount ?? 0)}',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Catatan (Wajib jika ditolak)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _tolak,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _terima,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Terima Lunas'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
