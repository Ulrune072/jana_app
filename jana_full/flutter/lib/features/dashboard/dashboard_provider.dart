import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../shared/models/alert.dart';

class DashboardData {
  final Map<String, double?> readings;
  final int unreadAlerts;
  final List<Alert> alerts;
  final DateTime lastFetched; // so the UI can show "updated X seconds ago"

  const DashboardData({
    required this.readings,
    required this.unreadAlerts,
    required this.alerts,
    required this.lastFetched,
  });
}

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardData>> {
  final Dio _api = createApiClient();
  Timer? _timer;

  DashboardNotifier() : super(const AsyncValue.loading()) {
    load();
    // auto-refresh every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      print('[dashboard] auto-refresh triggered');
      load(silent: true); // silent = don't show loading spinner on auto-refresh
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // silent: true means keep showing existing data while refreshing in background
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }

    print('[dashboard] fetching latest readings...');

    try {
      final results = await Future.wait([
        _api.get('/api/biomarkers/latest'),
        _api.get('/api/alerts'),
      ]);

      final latestRaw = results[0].data['data'] as Map<String, dynamic>;
      final alertsRaw = results[1].data['data'] as List;
      final unread    = results[1].data['unread'] as int? ?? 0;

      final readings = <String, double?>{};
      for (final entry in latestRaw.entries) {
        final value = (entry.value['value'] as num?)?.toDouble();
        readings[entry.key] = value;
        print('[dashboard] ${entry.key}: $value');
      }

      final now = DateTime.now();
      print('[dashboard] fetch complete at $now — ${readings.length} types');

      final alerts = alertsRaw.map((a) => Alert.fromJson(a)).toList();

      state = AsyncValue.data(DashboardData(
        readings:     readings,
        unreadAlerts: unread,
        alerts:       alerts,
        lastFetched:  now,
      ));
    } on DioException catch (e) {
      print('[dashboard] fetch error: ${e.response?.statusCode} — ${e.response?.data}');
      // on auto-refresh failure, keep showing old data instead of error screen
      if (silent && state is AsyncData) return;
      state = AsyncValue.error(
        e.response?.data?['error'] ?? 'Failed to load data',
        StackTrace.current,
      );
    }
  }

  Future<void> submitManualReading(String type, double value) async {
    try {
      await _api.post('/api/biomarkers/ingest', data: [
        {'type': type, 'value': value, 'source': 'manual'},
      ]);
      await load();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Failed to submit reading');
    }
  }
}

final dashboardProvider =
StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardData>>(
      (ref) => DashboardNotifier(),
);