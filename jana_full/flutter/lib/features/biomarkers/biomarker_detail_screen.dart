import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';
import '../../core/api_client.dart';
import '../../shared/models/biomarker_reading.dart';
import 'biomarker_config.dart';

// Keyed by "type:range" e.g. "heart_rate:week"
// Using autoDispose so Riverpod re-fetches when you re-open the screen
// rather than showing stale cached data.
final biomarkerHistoryProvider =
FutureProvider.autoDispose.family<List<BiomarkerReading>, String>(
      (ref, key) async {
    final separatorIndex = key.lastIndexOf(':');
    final type  = key.substring(0, separatorIndex);
    final range = key.substring(separatorIndex + 1);

    print('[detail] ── START ──────────────────────────');
    print('[detail] key:   $key');
    print('[detail] type:  $type');
    print('[detail] range: $range');

    final api = createApiClient();

    // log what token we're actually sending
    final session = Supabase.instance.client.auth.currentSession;
    print('[detail] session null? ${session == null}');
    if (session != null) {
      final exp = session.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('[detail] token expires in ${exp != null ? exp - now : "unknown"} seconds');
      print('[detail] token prefix: ${session.accessToken.substring(0, 20)}...');
    }

    final url = '/api/biomarkers/$type/history';
    print('[detail] requesting: GET $url?range=$range');

    try {
      final res = await api.get(
        url,
        queryParameters: {'range': range},
      );

      print('[detail] status:   ${res.statusCode}');
      print('[detail] response: ${res.data}');

      final list = res.data['data'] as List? ?? [];
      print('[detail] parsed ${list.length} readings');
      print('[detail] ── END ────────────────────────────');

      return list.map((j) => BiomarkerReading.fromJson(j)).toList();

    } on DioException catch (e) {
      print('[detail] !! DioException');
      print('[detail] !! type:     ${e.type}');
      print('[detail] !! status:   ${e.response?.statusCode}');
      print('[detail] !! response: ${e.response?.data}');
      print('[detail] !! message:  ${e.message}');
      print('[detail] !! error:    ${e.error}');
      rethrow;
    } catch (e, stack) {
      print('[detail] !! unexpected error: $e');
      print('[detail] !! stack: $stack');
      rethrow;
    }
  },
);

// Using autoDispose here too so the toggle resets when you leave the screen
final _rangeProvider =
    StateProvider.autoDispose.family<String, String>(
  (ref, type) => 'week',
);

class BiomarkerDetailScreen extends ConsumerWidget {
  final String biomarkerType;
  const BiomarkerDetailScreen({super.key, required this.biomarkerType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = biomarkerConfigs[biomarkerType];

    if (config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unknown biomarker')),
        body: Center(child: Text('No config for "$biomarkerType"')),
      );
    }

    final range   = ref.watch(_rangeProvider(biomarkerType));
    // key format: "heart_rate:week" — use lastIndexOf so blood_pressure_sys
    // doesn't get split on an underscore
    final history = ref.watch(
        biomarkerHistoryProvider('$biomarkerType:$range'));

    final bgColor    = config.isDark
        ? const Color(0xFF121212)
        : AppColors.background;
    final textColor  = config.isDark
        ? Colors.white
        : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                context:      context,
                config:       config,
                history:      history,
                textColor:    textColor,
              ),
            ),

            // ── Day / Week / Month toggle ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _RangeToggle(
                  biomarkerType: biomarkerType,
                  range:         range,
                  isDark:        config.isDark,
                ),
              ),
            ),

            // ── Chart + stats + list ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: history.when(
                  loading: () => SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                  ),
                  error: (e, _) => SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off,
                              color: AppColors.textSecondary, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            e.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(
                                biomarkerHistoryProvider(
                                    '$biomarkerType:$range')),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (readings) => readings.isEmpty
                      ? _EmptyState(config: config, textColor: textColor)
                      : _Content(
                          config:        config,
                          readings:      readings,
                          biomarkerType: biomarkerType,
                        ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final BuildContext context;
  final BiomarkerConfig config;
  final AsyncValue<List<BiomarkerReading>> history;
  final Color textColor;

  const _Header({
    required this.context,
    required this.config,
    required this.history,
    required this.textColor,
  });

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_ios,
                  size: 20, color: textColor),
            ),
            const SizedBox(width: 8),
            Text(config.emoji,
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                config.label,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          // only show subtitle when data is loaded and non-empty
          history.maybeWhen(
            data: (readings) {
              if (readings.isEmpty) return const SizedBox.shrink();
              final last    = readings.last;
              final dateStr = _safeDate(last.recordedAt);
              return Text(
                'Latest: ${_fmt(last.value, config.type)}'
                ' ${config.unitShort}'
                '${dateStr.isNotEmpty ? "  ·  $dateStr" : ""}',
                style: TextStyle(
                  color: config.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Range toggle — uses AppColors.primary to match the rest of the app ────────
class _RangeToggle extends ConsumerWidget {
  final String biomarkerType, range;
  final bool isDark;

  const _RangeToggle({
    required this.biomarkerType,
    required this.range,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // restored to the original green color scheme used everywhere else
    final bg       = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inactive = isDark ? Colors.white60 : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: ['day', 'week', 'month'].map((r) {
          final selected = range == r;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref
                  .read(_rangeProvider(biomarkerType).notifier)
                  .state = r,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  // uses AppColors.primary (green) for all biomarkers —
                  // consistent with the rest of the app
                  color: selected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  r[0].toUpperCase() + r.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected ? Colors.white : inactive,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────
class _Content extends StatelessWidget {
  final BiomarkerConfig config;
  final List<BiomarkerReading> readings;
  final String biomarkerType;

  const _Content({
    required this.config,
    required this.readings,
    required this.biomarkerType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // chart
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: config.chartBgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: config.accentColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
          child: biomarkerType == 'steps'
              ? _StepsChart(readings: readings, config: config)
              : _LineChart(readings: readings, config: config),
        ),
        const SizedBox(height: 20),
        _StatsRow(readings: readings, config: config),
        const SizedBox(height: 20),
        _ReadingsList(readings: readings, config: config),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final BiomarkerConfig config;
  final Color textColor;
  const _EmptyState({required this.config, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(config.emoji,
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No data for this period',
                style: TextStyle(color: textColor, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Add readings manually or run the simulator',
              style: TextStyle(
                  color: textColor.withOpacity(0.6), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line chart ────────────────────────────────────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<BiomarkerReading> readings;
  final BiomarkerConfig config;
  const _LineChart({required this.readings, required this.config});

  @override
  Widget build(BuildContext context) {
    final spots = readings.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    // fl_chart needs ≥ 2 points to draw a line
    final chartSpots =
        spots.length == 1 ? [spots[0], FlSpot(1, spots[0].y)] : spots;

    final values = readings.map((r) => r.value).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final effMin =
        config.minY ?? (minVal - minVal * 0.05).floorToDouble();
    final effMax =
        config.maxY ?? (maxVal + maxVal * 0.05).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: effMin,
        maxY: effMax,
        rangeAnnotations: config.zones != null
            ? RangeAnnotations(
                horizontalRangeAnnotations: config.zones!
                    .map((z) => HorizontalRangeAnnotation(
                        y1: z.y1, y2: z.y2, color: z.color))
                    .toList(),
              )
            : null,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: config.isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                _fmt(v, config.type),
                style: TextStyle(
                  color: config.isDark
                      ? Colors.white54
                      : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:    chartSpots,
            isCurved: true,
            color:    config.chartLineColor,
            barWidth: 2.5,
            belowBarData: BarAreaData(
              show:  true,
              color: config.chartLineColor
                  .withOpacity(config.isDark ? 0.15 : 0.1),
            ),
            dotData: FlDotData(
              show: readings.length < 30,
              getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(
                radius:      3.5,
                color:       config.chartLineColor,
                strokeColor: config.isDark
                    ? Colors.black
                    : Colors.white,
                strokeWidth: 1.5,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => config.isDark
                ? const Color(0xFF2A2A3A)
                : Colors.white,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${_fmt(s.y, config.type)} ${config.unitShort}',
                      TextStyle(
                        color: config.isDark
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ── Steps bar chart ───────────────────────────────────────────────────────────
class _StepsChart extends StatelessWidget {
  final List<BiomarkerReading> readings;
  final BiomarkerConfig config;
  const _StepsChart({required this.readings, required this.config});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: readings.asMap().entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY:   e.value.value,
                      color: config.chartLineColor,
                      width: readings.length > 20 ? 4 : 10,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                ))
            .toList(),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.black.withOpacity(0.06),
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles:   true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
          ),
          bottomTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
              '${rod.toY.toInt()} steps',
              const TextStyle(
                color:      AppColors.textPrimary,
                fontSize:   13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<BiomarkerReading> readings;
  final BiomarkerConfig config;
  const _StatsRow({required this.readings, required this.config});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return const SizedBox.shrink();

    final values = readings.map((r) => r.value).toList();
    final avg    = values.reduce((a, b) => a + b) / values.length;
    final min    = values.reduce((a, b) => a < b ? a : b);
    final max    = values.reduce((a, b) => a > b ? a : b);
    final isDark = config.isDark;

    return Row(children: [
      _Stat(label: 'Min', value: _fmt(min, config.type),
        unit: config.unitShort, color: config.accentColor, isDark: isDark),
      const SizedBox(width: 10),
      _Stat(label: 'Avg', value: _fmt(avg, config.type),
        unit: config.unitShort, color: config.accentColor, isDark: isDark),
      const SizedBox(width: 10),
      _Stat(label: 'Max', value: _fmt(max, config.type),
        unit: config.unitShort, color: config.accentColor, isDark: isDark),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  final bool isDark;
  const _Stat({required this.label, required this.value,
    required this.unit, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg  = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final lbl = isDark ? Colors.white54 : AppColors.textSecondary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Text(label, style: TextStyle(
            fontSize: 12, color: lbl, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: TextStyle(fontSize: 11, color: lbl)),
        ]),
      ),
    );
  }
}

// ── Readings list ─────────────────────────────────────────────────────────────
class _ReadingsList extends StatelessWidget {
  final List<BiomarkerReading> readings;
  final BiomarkerConfig config;
  const _ReadingsList({required this.readings, required this.config});

  @override
  Widget build(BuildContext context) {
    final toShow  = readings.reversed.take(15).toList();
    final isDark  = config.isDark;
    final cardBg  = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final divClr  = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFF0F0F0);
    final lbl     = isDark ? Colors.white54 : AppColors.textSecondary;
    final val     = isDark ? Colors.white   : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Recent readings',
              style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.w600, color: lbl)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: toShow.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: divClr),
            itemBuilder: (_, i) {
              final r = toShow[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: config.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Text(_safeDate(r.recordedAt),
                    style: TextStyle(fontSize: 13, color: lbl)),
                  const Spacer(),
                  Text(
                    '${_fmt(r.value, config.type)} ${config.unitShort}',
                    style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: val),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: config.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(r.source,
                      style: TextStyle(fontSize: 10,
                        color: config.accentColor,
                        fontWeight: FontWeight.w500)),
                  ),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v, String type) {
  if (type == 'steps')             return v.toInt().toString();
  if (type == 'blood_glucose')     return v.toStringAsFixed(1);
  if (type == 'oxygen_saturation') return v.toStringAsFixed(0);
  return v.toStringAsFixed(0);
}

String _safeDate(String? raw) {
  if (raw == null || raw.isEmpty) return '--';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return '--';
  final local = dt.toLocal();
  return '${local.day}/${local.month}  '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
