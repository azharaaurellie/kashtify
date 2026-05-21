import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/kas_provider.dart';
import '../../widgets/loading_button.dart';

class CatatTransaksiScreen extends ConsumerStatefulWidget {
  const CatatTransaksiScreen({super.key});

  @override
  ConsumerState<CatatTransaksiScreen> createState() =>
      _CatatTransaksiScreenState();
}

class _CatatTransaksiScreenState extends ConsumerState<CatatTransaksiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'pemasukan';
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak terautentikasi');

      final amountStr =
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      await ref.read(kasServiceProvider).insertTransaction({
        'created_by': userId,
        'type': _type,
        'amount': int.parse(amountStr),
        'description': _descController.text.trim(),
        'date': _date.toIso8601String().split('T').first,
      });
      if (!mounted) return;
      ref.invalidate(kasSummaryProvider);
      ref.invalidate(transactionsProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Transaksi disimpan!')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                    labelText: 'Tipe Transaksi',
                    prefixIcon: Icon(Icons.swap_horiz)),
                items: const [
                  DropdownMenuItem(
                      value: 'pemasukan', child: Text('Pemasukan (+)')),
                  DropdownMenuItem(
                      value: 'pengeluaran', child: Text('Pengeluaran (-)')),
                ],
                onChanged: (v) => setState(() => _type = v!),
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
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi', prefixIcon: Icon(Icons.notes)),
                validator: (v) => v == null || v.isEmpty ? 'Harus diisi' : null,
              ),
              const SizedBox(height: 32),
              LoadingButton(
                  onPressed: _submit,
                  isLoading: _isLoading,
                  label: 'Simpan',
                  icon: Icons.save),
            ],
          ),
        ),
      ),
    );
  }
}
