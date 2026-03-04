import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/providers/settings_provider.dart';
import '../models/staff_models.dart';

part 'staff_provider.g.dart';

const _cacheKey = 'last_staff';

@riverpod
Future<StaffData> staffData(Ref ref) async {
  final api = ref.read(apiClientProvider);
  final scheduleId = ref.watch(activeScheduleNotifierProvider);

  try {
    final json = await api.fetchStaff(scheduleId: scheduleId);
    final data = StaffData.fromJson(json);

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
        return StaffData.fromJson(json);
      }
    } catch (_) {}
    rethrow;
  }
}
