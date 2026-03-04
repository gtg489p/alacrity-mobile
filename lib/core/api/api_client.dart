import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_endpoints.dart';

part 'api_client.g.dart';

const _defaultBaseUrl = 'https://api.alacrity.live';

@riverpod
String apiBaseUrl(Ref ref) {
  final box = Hive.box('settings');
  return box.get('api_base_url', defaultValue: _defaultBaseUrl) as String;
}

@riverpod
Dio dio(Ref ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      retries: 2,
      retryDelays: const [Duration(seconds: 1), Duration(seconds: 3)],
    ),
  );

  assert(() {
    dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
    return true;
  }());

  return dio;
}

@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient(ref.watch(dioProvider));
}

class ConnectionTestResult {
  final bool success;
  final int? latencyMs;
  final String? factoryName;
  final String? error;

  const ConnectionTestResult({
    required this.success,
    this.latencyMs,
    this.factoryName,
    this.error,
  });
}

class ApiClient {
  final Dio _dio;
  ApiClient(this._dio);

  Future<List<Map<String, dynamic>>> fetchParetoFront({int limit = 200}) async {
    final response = await _dio.get(
      ApiEndpoints.paretoFront,
      queryParameters: {'limit': limit},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchGantt({int? scheduleId}) async {
    final response = await _dio.get(
      ApiEndpoints.gantt,
      queryParameters: {
        'output_format': 'json',
        if (scheduleId != null) 'schedule_id': scheduleId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchFactoryState() async {
    final response = await _dio.get(ApiEndpoints.factoryState);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchMaterial({int? scheduleId}) async {
    final response = await _dio.get(
      ApiEndpoints.material,
      queryParameters: {
        'output_format': 'json',
        if (scheduleId != null) 'schedule_id': scheduleId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchStaff({int? scheduleId}) async {
    final response = await _dio.get(
      ApiEndpoints.staff,
      queryParameters: {
        'output_format': 'json',
        if (scheduleId != null) 'schedule_id': scheduleId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchFg({int? scheduleId}) async {
    final response = await _dio.get(
      ApiEndpoints.fg,
      queryParameters: {
        'output_format': 'json',
        if (scheduleId != null) 'schedule_id': scheduleId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchTrucks({int? scheduleId}) async {
    final response = await _dio.get(
      ApiEndpoints.trucks,
      queryParameters: {
        'output_format': 'json',
        if (scheduleId != null) 'schedule_id': scheduleId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ConnectionTestResult> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get(ApiEndpoints.factoryState);
      stopwatch.stop();
      final data = response.data as Map<String, dynamic>;
      final mixTanks = data['mix_tanks'] as List?;
      final factoryName =
          mixTanks?.isNotEmpty == true
              ? (mixTanks![0] as Map<String, dynamic>)['factory_name']
                  as String?
              : null;
      return ConnectionTestResult(
        success: true,
        latencyMs: stopwatch.elapsedMilliseconds,
        factoryName: factoryName ?? 'Unknown',
      );
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(success: false, error: e.toString());
    }
  }
}
