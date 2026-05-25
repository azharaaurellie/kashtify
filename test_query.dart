import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://xcjbbwujmpjmczorwwzf.supabase.co', 'sb_publishable_ecmC5NDNxIa6nsn684tFeg_cy_KH9XN');
  final data = await client.from('fund_requests').select();
  print(data);
}
