import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../models/disruption_models.dart';

part 'alerts_provider.g.dart';

@riverpod
Future<List<Disruption>> disruptionList(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.fetchDisruptions();
  return response.map((j) => Disruption.fromJson(j)).toList();
}
