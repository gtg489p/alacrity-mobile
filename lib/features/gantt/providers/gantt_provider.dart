import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/settings_provider.dart';
import '../models/gantt_models.dart';

part 'gantt_provider.g.dart';

const _cacheKey = 'last_gantt';

@riverpod
Future<GanttData> ganttData(Ref ref) async {
  final api = ref.read(apiClientProvider);
  final scheduleId = ref.watch(activeScheduleNotifierProvider);

  try {
    final json = await api.fetchGantt(scheduleId: scheduleId);
    final data = GanttData.fromJson(json);

    // Cache to Hive
    try {
      final box = Hive.box('settings');
      box.put(_cacheKey, jsonEncode(json));
    } catch (_) {
      // Cache write failure is non-fatal
    }

    return data;
  } catch (e) {
    // Try loading from cache on failure
    try {
      final box = Hive.box('settings');
      final cached = box.get(_cacheKey) as String?;
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return GanttData.fromJson(json);
      }
    } catch (_) {
      // Cache read failure — rethrow original error
    }
    rethrow;
  }
}

@riverpod
GanttLayout ganttLayout(Ref ref) {
  final data = ref.watch(ganttDataProvider).requireValue;
  return GanttLayout(data);
}
