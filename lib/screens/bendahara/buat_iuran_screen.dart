import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/iuran_provider.dart';
import '../../widgets/loading_button.dart';

class BuatIuranScreen extends ConsumerStatefulWidget {
  const BuatIuranScreen({super.key});

  @override
  ConsumerState<BuatIuranScreen> createState() => _BuatIuranScreenState();
}

class _BuatIuranScreenState extends ConsumerState<BuatIuranScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih batas waktu bayar')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak terautentikasi');

      final amountStr =
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      await ref.read(iuranServiceProvider).createIuran({
        'created_by': userId,
        'title': _titleController.text.trim(),
        'amount': int.parse(amountStr),
        'due_date': _dueDate!.toIso8601String().split('T').first,
        'description': _descController.text.trim(),
      });
      if (!mounted) return;
      ref.invalidate(iuranSummaryProvider);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tagihan berhasil dibuat!')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'), backgroundColor: AppTheme.errorColor));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tagihan Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Judul Tagihan', prefixIcon: Icon(Icons.title)),
                validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Nominal (Rp)',
                    prefixIcon: Icon(Icons.attach_money)),
                validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Batas Waktu',
                      prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(_dueDate != null
                      ? DateFormat('d MMMM yyyy', 'id_ID').format(_dueDate!)
                      : 'Pilih Tanggal'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    prefixIcon: Icon(Icons.notes)),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              LoadingButton(
                  onPressed: _submit,
                  isLoading: _isLoading,
                  label: 'Buat Tagihan',
                  icon: Icons.post_add),
            ],
          ),
        ),
      ),
    );
  }
}
