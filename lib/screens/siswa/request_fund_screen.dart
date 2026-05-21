import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/fund_request_provider.dart';
import '../../widgets/loading_button.dart';

class RequestFundScreen extends ConsumerStatefulWidget {
  const RequestFundScreen({super.key});

  @override
  ConsumerState<RequestFundScreen> createState() => _RequestFundScreenState();
}

class _RequestFundScreenState extends ConsumerState<RequestFundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keperluanController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _alasanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _keperluanController.dispose();
    _jumlahController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak terautentikasi');

      await ref.read(fundRequestServiceProvider).createRequest(
            requestedBy: userId,
            title: _keperluanController.text.trim(),
            amount: int.parse(
              _jumlahController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ),
            reason: _alasanController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan berhasil, menunggu persetujuan bendahara'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Dana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Pengajuan Dana',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Isi formulir di bawah untuk mengajukan dana ke bendahara',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _keperluanController,
                decoration: const InputDecoration(
                  labelText: 'Keperluan',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Keperluan harus diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Dana (Rupiah)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'contoh: 150000',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah harus diisi';
                  final amount =
                      int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (amount == null || amount <= 0) {
                    return 'Jumlah tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alasanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan / Keterangan',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Alasan harus diisi' : null,
              ),
              const SizedBox(height: 28),
              LoadingButton(
                onPressed: _submit,
                isLoading: _isLoading,
                label: 'Ajukan Dana',
                icon: Icons.send_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
