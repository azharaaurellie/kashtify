import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kas_summary_model.dart';
import '../models/transaction_model.dart';

class KasService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<KasSummaryModel?> getKasSummary() async {
    final data = await _supabase.from('kas_summary').select().maybeSingle();
    if (data == null) {
      return const KasSummaryModel(
          totalPemasukan: 0, totalPengeluaran: 0, saldo: 0);
    }
    return KasSummaryModel.fromMap(data);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final data = await _supabase
        .from('transactions')
        .select('''
          *,
          profiles(full_name)
        ''')
        .order('date', ascending: false);
    return (data as List)
        .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
      int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final startStr = start.toIso8601String().split('T').first;
    final endStr = end.toIso8601String().split('T').first;

    final data = await _supabase
        .from('transactions')
        .select('''
          *,
          profiles(full_name)
        ''')
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false);
    return (data as List)
        .map((item) => TransactionModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> insertTransaction(Map<String, dynamic> data) async {
    await _supabase.from('transactions').insert(data);
  }
}