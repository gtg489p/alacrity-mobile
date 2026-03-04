import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/settings_provider.dart';
import '../../gantt/models/gantt_models.dart';
import '../models/wip_models.dart';

part 'wip_provider.g.dart';

@riverpod
Future<WipData> wipData(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  final scheduleId = ref.watch(activeScheduleNotifierProvider);

  final json = await api.fetchGantt(scheduleId: scheduleId);
  final ganttData = GanttData.fromJson(json);

  return _deriveWip(ganttData);
}

/// Derive WIP curve from Gantt job start/end times.
/// +1 at each job start, -1 at each job end, then accumulate.
WipData _deriveWip(GanttData gantt) {
  // Build events: (time, delta, jobName)
  final events = <({DateTime time, int delta, String label})>[];
  for (final job in gantt.jobs) {
    final start = DateTime.parse(job.start);
    final end = DateTime.parse(job.end);
    events.add((time: start, delta: 1, label: '${job.row} — ${job.name}'));
    events.add((time: end, delta: -1, label: '${job.row} — ${job.name}'));
  }

  // Sort by time (starts before ends at same instant)
  events.sort((a, b) {
    final cmp = a.time.compareTo(b.time);
    if (cmp != 0) return cmp;
    return a.delta.compareTo(b.delta); // -1 before +1 at same time
  });

  if (events.isEmpty) {
    return WipData(
      points: [],
      peakWip: 0,
      peakTime: DateTime.now(),
      scheduleId: gantt.scheduleId,
    );
  }

  // Accumulate running count, tracking active jobs
  final points = <WipPoint>[];
  var current = 0;
  var peakWip = 0;
  var peakTime = events.first.time;
  final activeJobs = <String>[];

  for (final event in events) {
    if (event.delta > 0) {
      activeJobs.add(event.label);
    } else {
      activeJobs.remove(event.label);
    }
    current += event.delta;

    points.add(WipPoint(
      time: event.time,
      concurrentJobs: current,
      activeJobNames: List.of(activeJobs),
    ));

    if (current > peakWip) {
      peakWip = current;
      peakTime = event.time;
    }
  }

  return WipData(
    points: points,
    peakWip: peakWip,
    peakTime: peakTime,
    scheduleId: gantt.scheduleId,
  );
}
