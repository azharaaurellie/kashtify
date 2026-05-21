import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/kas_service.dart';
import '../models/kas_summary_model.dart';
import '../models/transaction_model.dart';

final kasServiceProvider = Provider<KasService>((ref) => KasService());

final kasSummaryProvider =
    FutureProvider.autoDispose<KasSummaryModel?>((ref) async {
  return await ref.watch(kasServiceProvider).getKasSummary();
});

final transactionsProvider =
    FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  return await ref.watch(kasServiceProvider).getTransactions();
});

// Family: takes (year, month) as int pair
final transactionsByMonthProvider = FutureProvider.autoDispose
    .family<List<TransactionModel>, (int, int)>((ref, params) async {
  final (year, month) = params;
  return await ref
      .watch(kasServiceProvider)
      .getTransactionsByMonth(year, month);
});
