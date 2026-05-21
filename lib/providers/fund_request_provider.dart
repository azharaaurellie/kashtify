import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fund_request_model.dart';
import '../services/fund_request_service.dart';

final fundRequestServiceProvider =
    Provider<FundRequestService>((ref) => FundRequestService());

final pendingFundRequestsProvider =
    FutureProvider.autoDispose<List<FundRequestModel>>((ref) async {
  return await ref.watch(fundRequestServiceProvider).getPendingRequests();
});
