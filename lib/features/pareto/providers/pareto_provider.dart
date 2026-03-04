import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../models/pareto_models.dart';

part 'pareto_provider.g.dart';

@riverpod
Future<List<ParetoSolution>> paretoFront(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final rawList = await api.fetchParetoFront(limit: 100);
  return rawList.map((j) => ParetoSolution.fromJson(j)).toList();
}
