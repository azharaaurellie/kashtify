import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/iuran_payment_model.dart';
import '../models/iuran_summary_model.dart';
import '../models/siswa_payment_summary_model.dart';

class IuranService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _paymentProofBucket = 'payment-proofs';

  Future<void> ensureStudentPaymentsExist(String siswaId) async {
    final iuranData = await _supabase.from('iuran').select('id');
    if ((iuranData as List).isEmpty) return;

    final existingPayments = await _supabase
        .from('iuran_payments')
        .select('iuran_id')
        .eq('siswa_id', siswaId);

    final existingIuranIds = (existingPayments as List)
        .map((item) => (item as Map<String, dynamic>)['iuran_id'] as String?)
        .whereType<String>()
        .toSet();

    final missingPayments = (iuranData as List)
        .cast<Map<String, dynamic>>()
        .where((item) => !existingIuranIds.contains(item['id']))
        .map((item) => {
              'iuran_id': item['id'],
              'siswa_id': siswaId,
              'status': 'belum_lunas',
            })
        .toList();

    if (missingPayments.isEmpty) return;

    await _supabase.from('iuran_payments').upsert(
          missingPayments,
          onConflict: 'iuran_id,siswa_id',
        );
  }

  Future<List<IuranPaymentModel>> getMyPayments(String siswaId) async {
    await ensureStudentPaymentsExist(siswaId);
    final data = await _supabase
        .from('iuran_payments')
        .select('*, iuran(title, amount, due_date)')
        .eq('siswa_id', siswaId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((item) => IuranPaymentModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<IuranPaymentModel>> getUnpaidPayments(String siswaId) async {
    await ensureStudentPaymentsExist(siswaId);
    final data = await _supabase
        .from('iuran_payments')
        .select('*, iuran(title, amount, due_date)')
        .eq('siswa_id', siswaId)
        .neq('status', 'lunas')
        .order('created_at', ascending: false);
    return (data as List)
        .map((item) => IuranPaymentModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<IuranPaymentModel>> getPendingVerifikasi() async {
    final data = await _supabase
        .from('iuran_payments')
        .select('*, siswa:profiles!siswa_id(full_name, nis), iuran(title, amount)')
        .eq('notes', 'menunggu_konfirmasi')
        .neq('status', 'lunas');
    return (data as List)
        .map((item) => IuranPaymentModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createIuran(Map<String, dynamic> data) async {
    await _supabase.from('iuran').insert(data);
  }

  Future<void> submitPembayaran(String iuranId, String userId) async {
    await ensureStudentPaymentsExist(userId);
    await _supabase
        .from('iuran_payments')
        .update({'notes': 'menunggu_konfirmasi'})
        .eq('iuran_id', iuranId)
        .eq('siswa_id', userId);
  }

  Future<void> submitPembayaranDenganBukti({
    required String iuranId,
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    await ensureStudentPaymentsExist(userId);
    final extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final storagePath =
        '$userId/$iuranId-${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _supabase.storage.from(_paymentProofBucket).uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _resolveContentType(extension),
          ),
        );

    final paymentProofUrl =
        _supabase.storage.from(_paymentProofBucket).getPublicUrl(storagePath);
    await _supabase
        .from('iuran_payments')
        .update({
          'notes': 'menunggu_konfirmasi',
          'payment_proof_url': paymentProofUrl,
        })
        .eq('iuran_id', iuranId)
        .eq('siswa_id', userId);
  }

  Future<void> konfirmasiLunas({
    required String paymentId,
    required String bendaharaId,
    required String siswaId,
    required String iuranTitle,
    required int amount,
    String? notes,
  }) async {
    final now = DateTime.now().toIso8601String();
    // 1. Update payment status to lunas
    await _supabase.from('iuran_payments').update({
      'status': 'lunas',
      'confirmed_by': bendaharaId,
      'notes': notes,
      'paid_at': now,
    }).eq('id', paymentId);

    // 2. Insert a transaction record for the income
    await _supabase.from('transactions').insert({
      'created_by': bendaharaId,
      'type': 'pemasukan',
      'amount': amount,
      'description': 'Pembayaran iuran: $iuranTitle (siswa ID: $siswaId)',
      'date': DateTime.now().toIso8601String().split('T').first,
    });
  }

  Future<void> tolakPembayaran(String paymentId, {String? notes}) async {
    await _supabase.from('iuran_payments').update({
      'notes': notes ?? 'Ditolak: Bukti pembayaran tidak valid',
      'payment_proof_url': null,
    }).eq('id', paymentId);
  }

  Future<List<IuranSummaryModel>> getIuranSummary() async {
    final data = await _supabase
        .from('iuran_summary')
        .select()
        .order('due_date', ascending: false);
    return (data as List)
        .map((item) => IuranSummaryModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SiswaPaymentSummaryModel>> getSiswaSummary() async {
    final data = await _supabase
        .from('siswa_payment_summary')
        .select()
        .order('total_tunggakan', ascending: false);
    return (data as List)
        .map((item) =>
            SiswaPaymentSummaryModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  String _resolveContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
