import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final box = Hive.box('settings');
    final saved = box.get('theme_mode', defaultValue: 'dark') as String;
    return ThemeMode.values.byName(saved);
  }

  void setThemeMode(ThemeMode mode) {
    Hive.box('settings').put('theme_mode', mode.name);
    state = mode;
  }
}

@riverpod
class ActiveScheduleNotifier extends _$ActiveScheduleNotifier {
  @override
  int? build() {
    final box = Hive.box('settings');
    return box.get('active_schedule_id') as int?;
  }

  void setSchedule(int id) {
    Hive.box('settings').put('active_schedule_id', id);
    state = id;
  }
}
