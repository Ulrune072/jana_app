import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../shared/models/alert.dart';

// what the dashboard screen needs to show
class DashboardData {
  final Map<String, double?> readings; // type -> value
  final int unreadAlerts;
  final List<Alert> alerts;

  const DashboardData({
    required this.readings,
    required this.unreadAlerts,
    required this.alerts,
  });
}

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardData>> {
  final Dio _api = createApiClient();

  DashboardNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      // fetch latest readings and alerts in parallel
      final results = await Future.wait([
        _api.get('/api/biomarkers/latest'),
        _api.get('/api/alerts'),
      ]);

      final latestRaw = results[0].data['data'] as Map<String, dynamic>;
      final alertsRaw = results[1].data['data'] as List;
      final unread    = results[1].data['unread'] as int? ?? 0;

      // flatten readings to Map<type, value>
      final readings = <String, double?>{};
      for (final entry in latestRaw.entries) {
        readings[entry.key] = (entry.value['value'] as num?)?.toDouble();
      }

      final alerts = alertsRaw.map((a) => Alert.fromJson(a)).toList();

      state = AsyncValue.data(DashboardData(
        readings:     readings,
        unreadAlerts: unread,
        alerts:       alerts,
      ));
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data?['error'] ?? 'Failed to load data',
        StackTrace.current,
      );
    }
  }

  // called by manual input form
  Future<void> submitManualReading(String type, double value) async {
    try {
      await _api.post('/api/biomarkers/ingest', data: [
        {'type': type, 'value': value, 'source': 'manual'},
      ]);
      await load(); // refresh dashboard after adding a reading
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? 'Failed to submit reading');
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardData>>(
  (ref) => DashboardNotifier(),
);
