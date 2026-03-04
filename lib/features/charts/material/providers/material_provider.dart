import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/providers/settings_provider.dart';
import '../models/material_models.dart';

part 'material_provider.g.dart';

const _cacheKey = 'last_material';

@riverpod
Future<MaterialData> materialData(Ref ref) async {
  final api = ref.read(apiClientProvider);
  final scheduleId = ref.watch(activeScheduleNotifierProvider);

  try {
    final json = await api.fetchMaterial(scheduleId: scheduleId);
    final data = MaterialData.fromJson(json);

    try {
      final box = Hive.box('settings');
      box.put(_cacheKey, jsonEncode(json));
    } catch (_) {}

    return data;
  } catch (e) {
    try {
      final box = Hive.box('settings');
      final cached = box.get(_cacheKey) as String?;
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return MaterialData.fromJson(json);
      }
    } catch (_) {}
    rethrow;
  }
}
