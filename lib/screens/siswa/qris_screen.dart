import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/iuran_provider.dart';
import '../../widgets/loading_button.dart';

class QrisScreen extends ConsumerStatefulWidget {
  final String iuranId;
  final int amount;
  final String title;

  const QrisScreen({
    super.key,
    required this.iuranId,
    required this.amount,
    required this.title,
  });

  @override
  ConsumerState<QrisScreen> createState() => _QrisScreenState();
}

class _QrisScreenState extends ConsumerState<QrisScreen> {
  static const String _qrisAssetPath = 'assets/images/qris.png';
  bool _isLoading = false;
  Uint8List? _proofBytes;
  String? _proofName;

  Future<void> _pickProof() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File tidak bisa dibaca. Pilih gambar lain.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _proofBytes = file.bytes;
        _proofName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      final isLinuxZenityIssue =
          Platform.isLinux && e.toString().toLowerCase().contains('zenity');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLinuxZenityIssue
                ? 'File picker Linux butuh `zenity`. Install dulu lalu coba lagi.'
                : 'Gagal membuka file picker: $e',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_proofBytes == null || _proofName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload bukti pembayaran dulu sebelum kirim.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak terautentikasi');

      await ref.read(iuranServiceProvider).submitPembayaranDenganBukti(
            iuranId: widget.iuranId,
            userId: userId,
            fileBytes: _proofBytes!,
            fileName: _proofName!,
          );

      ref.invalidate(unpaidPaymentsProvider);
      ref.invalidate(myPaymentsProvider);
      ref.invalidate(pendingVerifikasiProvider);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(
            Icons.mark_email_read_outlined,
            color: AppTheme.accentColor,
            size: 48,
          ),
          title: const Text('Bukti Terkirim'),
          content: const Text(
            'Bukti pembayaran sudah dikirim ke bendahara dan sekarang menunggu konfirmasi.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.go('/history');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar via QRIS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alur Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const _FlowStep(
                    number: '1',
                    title: 'Scan QRIS dan bayar',
                    description: 'Lakukan transfer sesuai nominal tagihan.',
                    isActive: true,
                  ),
                  _FlowStep(
                    number: '2',
                    title: 'Kirim bukti pembayaran',
                    description:
                        'Upload screenshot atau foto transaksi yang berhasil.',
                    isActive: _proofBytes != null,
                  ),
                  const _FlowStep(
                    number: '3',
                    title: 'Menunggu konfirmasi bendahara',
                    description:
                        'Bendahara akan memeriksa bukti yang sudah kamu kirim.',
                  ),
                  const _FlowStep(
                    number: '4',
                    title: 'Berhasil bayar',
                    description:
                        'Status berubah menjadi lunas setelah diverifikasi.',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(widget.amount),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          _qrisAssetPath,
                          width: 280,
                          height: 280,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'QRIS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Setelah transfer berhasil, upload bukti pembayaran. Bendahara hanya bisa memverifikasi pembayaran yang sudah ada bukti.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickProof,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                _proofName == null
                    ? 'Upload Bukti Pembayaran'
                    : 'Ganti Bukti: $_proofName',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_proofBytes != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _proofBytes!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 28),
            LoadingButton(
              onPressed: _submit,
              isLoading: _isLoading,
              label: 'Kirim Bukti ke Bendahara',
              icon: Icons.send_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final bool isActive;
  final bool isLast;

  const _FlowStep({
    required this.number,
    required this.title,
    required this.description,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryColor : AppTheme.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppTheme.dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
