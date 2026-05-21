import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/qris_service.dart';

final qrisServiceProvider = Provider<QrisService>((ref) => QrisService());

final qrisDataProvider = FutureProvider.autoDispose<String?>((ref) async {
  return ref.watch(qrisServiceProvider).getQrisData();
});
