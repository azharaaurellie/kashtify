import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fund_request_model.dart';

class FundRequestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createRequest({
    required String requestedBy,
    required String title,
    required int amount,
    required String reason,
  }) async {
    await _supabase.from('fund_requests').insert({
      'requested_by': requestedBy,
      'title': title,
      'amount': amount,
      'reason': reason,
      'status': 'pending',
    });
  }

  Future<List<FundRequestModel>> getPendingRequests() async {
    final data = await _supabase
        .from('fund_requests')
        .select('*, profiles(full_name, nis)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List)
        .map((item) => FundRequestModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveRequest({
    required String requestId,
    required String bendaharaId,
    required String requesterId,
    required String title,
    required int amount,
    required String reason,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    await _supabase.from('fund_requests').update({
      'status': 'approved',
      'reviewed_by': bendaharaId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    await _supabase.from('transactions').insert({
      'created_by': bendaharaId,
      'type': 'pengeluaran',
      'amount': amount,
      'description': 'Pengajuan dana disetujui: $title ($reason) [pemohon: $requesterId]',
      'date': today,
    });
  }

  Future<void> rejectRequest({
    required String requestId,
    required String bendaharaId,
  }) async {
    await _supabase.from('fund_requests').update({
      'status': 'rejected',
      'reviewed_by': bendaharaId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}
