import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/role_constants.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _ensureStudentPaymentsExist(String siswaId) async {
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

  Future<ProfileModel?> getProfile(String userId) async {
    final currentUser = _supabase.auth.currentUser;
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      if (currentUser != null && currentUser.id == userId) {
        final newProfile = {
          'id': userId,
          'full_name': currentUser.userMetadata?['full_name'] as String? ??
              currentUser.email?.split('@').first ??
              'User',
          'nis': currentUser.userMetadata?['nis'] as String?,
          'role': 'siswa',
        };
        await _supabase.from('profiles').upsert(newProfile);
        return ProfileModel.fromMap({
          ...newProfile,
          'email': currentUser.email,
        });
      }
      return null;
    }

    return ProfileModel.fromMap({
      ...data,
      'email': currentUser?.id == userId ? currentUser?.email : data['email'],
    });
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _supabase.from('profiles').update(data).eq('id', userId);
  }

  Future<String?> getMyRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    if (data != null) {
      return normalizeRole(data['role'] as String?);
    }

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': user.userMetadata?['full_name'] as String? ??
          user.email?.split('@').first ??
          'User',
      'nis': user.userMetadata?['nis'] as String?,
      'role': 'siswa',
    });
    return normalizeRole('siswa');
  }

  Future<List<Map<String, dynamic>>> getSiswaPaymentDetail(
      String siswaId) async {
    await _ensureStudentPaymentsExist(siswaId);
    final data = await _supabase
        .from('iuran_payments')
        .select('*, iuran(title, amount, due_date)')
        .eq('siswa_id', siswaId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
