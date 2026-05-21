import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/iuran_service.dart';
import '../models/iuran_payment_model.dart';
import '../models/iuran_summary_model.dart';
import '../models/siswa_payment_summary_model.dart';

final iuranServiceProvider = Provider<IuranService>((ref) => IuranService());

final myPaymentsProvider = FutureProvider.autoDispose
    .family<List<IuranPaymentModel>, String>((ref, siswaId) async {
  return await ref.watch(iuranServiceProvider).getMyPayments(siswaId);
});

final unpaidPaymentsProvider = FutureProvider.autoDispose
    .family<List<IuranPaymentModel>, String>((ref, siswaId) async {
  return await ref.watch(iuranServiceProvider).getUnpaidPayments(siswaId);
});

final pendingVerifikasiProvider =
    FutureProvider.autoDispose<List<IuranPaymentModel>>((ref) async {
  return await ref.watch(iuranServiceProvider).getPendingVerifikasi();
});

final iuranSummaryProvider =
    FutureProvider.autoDispose<List<IuranSummaryModel>>((ref) async {
  return await ref.watch(iuranServiceProvider).getIuranSummary();
});

final siswaSummaryProvider =
    FutureProvider.autoDispose<List<SiswaPaymentSummaryModel>>((ref) async {
  return await ref.watch(iuranServiceProvider).getSiswaSummary();
});
