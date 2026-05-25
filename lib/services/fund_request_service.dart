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
      'student_id': requestedBy,                // ✅ requested_by → student_id
      'description': '$title\n\nAlasan: $reason', // ✅ title+reason → description
      'amount': amount,
      'status': 'pending',
    });
  }

  Future<List<FundRequestModel>> getPendingRequests() async {
    final data = await _supabase
        .from('fund_requests')
        .select() // NO JOIN, manual fetch below to prevent foreign key errors
        .eq('status', 'pending')
        .order('created_at', ascending: false);
        
    final requests = data as List;
    if (requests.isEmpty) return [];

    final studentIds = requests.map((e) => e['student_id'] as String?).whereType<String>().toSet().toList();
    
    Map<String, dynamic> profilesMap = {};
    if (studentIds.isNotEmpty) {
      try {
        final profilesData = await _supabase.from('profiles').select('id, full_name, nis').inFilter('id', studentIds);
        for (var p in profilesData as List) {
          profilesMap[p['id']] = p;
        }
      } catch (e) {
        // ignore profile fetch errors
      }
    }

    return requests.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      if (map['student_id'] != null && profilesMap.containsKey(map['student_id'])) {
        map['profiles'] = profilesMap[map['student_id']];
      }
      return FundRequestModel.fromMap(map);
    }).toList();
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

    // ✅ reviewed_by → resolved_by, reviewed_at → resolved_at
    await _supabase.from('fund_requests').update({
      'status': 'approved',
      'resolved_by': bendaharaId,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    // ✅ adjusted to match new setup_supabase.sql schema
    await _supabase.from('transactions').insert({
      'created_by': bendaharaId,
      'type': 'pengeluaran',
      'amount': amount,
      'description': 'Pengajuan dana disetujui: $title ($reason) untuk siswa ID: $requesterId',
      'date': today,
    });
  }

  Future<void> rejectRequest({
    required String requestId,
    required String bendaharaId,
  }) async {
    // ✅ reviewed_by → resolved_by, reviewed_at → resolved_at
    await _supabase.from('fund_requests').update({
      'status': 'rejected',
      'resolved_by': bendaharaId,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}