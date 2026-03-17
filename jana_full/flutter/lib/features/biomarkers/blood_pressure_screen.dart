import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import '../../core/app_theme.dart';
import '../../core/api_client.dart';
import '../../shared/models/biomarker_reading.dart';

final _rangeProvider = StateProvider<String>((ref) => 'week');

final _bpHistoryProvider = FutureProvider.family<List<BiomarkerReading>, String>(
  (ref, range) async {
    final api = createApiClient();
    final res = await api.get('/api/biomarkers/blood_pressure_sys/history',
      queryParameters: {'range': range});
    return (res.data['data'] as List)
        .map((j) => BiomarkerReading.fromJson(j))
        .toList();
  },
);

class BloodPressureScreen extends ConsumerWidget {
  const BloodPressureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range   = ref.watch(_rangeProvider);
    final history = ref.watch(_bpHistoryProvider(range));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Blood Pressure',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const SizedBox(height: 4),

            // last reading subtitle
            history.when(
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
              data: (readings) {
                if (readings.isEmpty) return const SizedBox.shrink();
                final last = readings.last;
                return Padding(
                  padding: const EdgeInsets.only(left: 52, bottom: 8),
                  child: Text(
                    'Last: ${last.value.toStringAsFixed(0)} mmHg',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                );
              },
            ),

            // Day / Week / Month toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(children: ['day', 'week', 'month'].map((r) =>
                  Expanded(child: GestureDetector(
                    onTap: () => ref.read(_rangeProvider.notifier).state = r,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: range == r ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        r[0].toUpperCase() + r.substring(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: range == r ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ))
                ).toList()),
              ),
            ),

            // chart
            Expanded(
              child: history.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (readings) => _BpChart(readings: readings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BpChart extends StatelessWidget {
  final List<BiomarkerReading> readings;
  const _BpChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No data for this period',
          style: TextStyle(color: AppColors.textSecondary)));
    }

    final spots = readings.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.value)).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2035),
          borderRadius: BorderRadius.circular(20),
        ),
        child: LineChart(
          LineChartData(
            minY: 60,
            maxY: 190,
            backgroundColor: const Color(0xFF1A2035),

            // coloured threshold zones - matches the Figma design
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(y1: 60,  y2: 90,  color: const Color(0x3343A047)),  // green safe low
                HorizontalRangeAnnotation(y1: 90,  y2: 120, color: const Color(0x33FFA726)),  // orange warning
                HorizontalRangeAnnotation(y1: 120, y2: 140, color: const Color(0x44FFA726)),  // deeper orange
                HorizontalRangeAnnotation(y1: 140, y2: 190, color: const Color(0x33E53935)),  // red critical
              ],
            ),

            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withOpacity(0.1), strokeWidth: 1),
              getDrawingVerticalLine: (_) => FlLine(
                color: Colors.white.withOpacity(0.05), strokeWidth: 1),
            ),

            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),

            borderData: FlBorderData(show: false),

            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: const Color(0xFF42A5F5),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF42A5F5),
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            ],

            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF2C3A5A),
                getTooltipItems: (spots) => spots.map((s) =>
                  LineTooltipItem(
                    '${s.y.toStringAsFixed(0)} mmHg',
                    const TextStyle(color: Colors.white, fontSize: 13),
                  )
                ).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
