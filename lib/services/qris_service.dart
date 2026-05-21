import 'package:supabase_flutter/supabase_flutter.dart';

class QrisService {
  QrisService();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'app_settings';
  static const String _key = 'qris';

  Future<String?> getQrisData() async {
    final data = await _supabase
        .from(_table)
        .select('value')
        .eq('key', _key)
        .maybeSingle();

    if (data == null) return null;
    final value = data['value'] as String?;
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> saveQrisData({
    required String qrisData,
    required String userId,
  }) async {
    await _supabase.from(_table).upsert({
      'key': _key,
      'value': qrisData.trim(),
      'updated_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'key');
  }
}
