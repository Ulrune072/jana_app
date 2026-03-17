import 'package:flutter/material.dart';

class BiomarkerConfig {
  final String type;
  final String label;
  final String unitShort; // used in chart tooltips and stat cards
  final String emoji;
  final Color  accentColor;
  final Color  chartLineColor;
  final Color  chartBgColor;
  final bool   isDark;
  final double? minY;
  final double? maxY;
  final List<ChartZone>? zones;

  const BiomarkerConfig({
    required this.type,
    required this.label,
    required this.unitShort,
    required this.emoji,
    required this.accentColor,
    required this.chartLineColor,
    required this.chartBgColor,
    required this.isDark,
    this.minY,
    this.maxY,
    this.zones,
  });
}

class ChartZone {
  final double y1, y2;
  final Color color;
  const ChartZone(this.y1, this.y2, this.color);
}

const Map<String, BiomarkerConfig> biomarkerConfigs = {

  'heart_rate': BiomarkerConfig(
    type:           'heart_rate',
    label:          'Heart Rate',
    unitShort:      'bpm',
    emoji:          '❤️',
    accentColor:    Color(0xFFE53935),
    chartLineColor: Color(0xFFEF9A9A),
    chartBgColor:   Color(0xFF1A1020),
    isDark:         true,
    minY:  30,
    maxY:  160,
    zones: [
      ChartZone(30,  40,  Color(0x44E53935)),
      ChartZone(40,  50,  Color(0x33FFA726)),
      ChartZone(50,  100, Color(0x2243A047)),
      ChartZone(100, 130, Color(0x33FFA726)),
      ChartZone(130, 160, Color(0x44E53935)),
    ],
  ),

  'blood_pressure_sys': BiomarkerConfig(
    type:           'blood_pressure_sys',
    label:          'Blood Pressure',
    unitShort:      'mmHg',
    emoji:          '🩸',
    accentColor:    Color(0xFF1E88E5),
    chartLineColor: Color(0xFF42A5F5),
    chartBgColor:   Color(0xFF1A2035),
    isDark:         true,
    minY:  60,
    maxY:  190,
    zones: [
      ChartZone(60,  90,  Color(0x3343A047)),
      ChartZone(90,  120, Color(0x33FFA726)),
      ChartZone(120, 140, Color(0x44FFA726)),
      ChartZone(140, 190, Color(0x44E53935)),
    ],
  ),

  'blood_glucose': BiomarkerConfig(
    type:           'blood_glucose',
    label:          'Blood Glucose',
    unitShort:      'mmol/L',
    emoji:          '💉',
    accentColor:    Color(0xFF00897B),
    chartLineColor: Color(0xFF26A69A),
    chartBgColor:   Color(0xFFF0FAF9),
    isDark:         false,
    minY:  2.0,
    maxY:  14.0,
    zones: [
      ChartZone(2.0,  3.0,  Color(0x33E53935)),
      ChartZone(3.0,  3.9,  Color(0x33FFA726)),
      ChartZone(3.9,  7.8,  Color(0x2200897B)),
      ChartZone(7.8,  11.0, Color(0x33FFA726)),
      ChartZone(11.0, 14.0, Color(0x33E53935)),
    ],
  ),

  'oxygen_saturation': BiomarkerConfig(
    type:           'oxygen_saturation',
    label:          'Oxygen Saturation',
    unitShort:      '%',
    emoji:          '🫁',
    accentColor:    Color(0xFF5E35B1),
    chartLineColor: Color(0xFF7E57C2),
    chartBgColor:   Color(0xFFF5F0FF),
    isDark:         false,
    minY:  85,
    maxY:  101,
    zones: [
      ChartZone(85, 90,  Color(0x44E53935)),
      ChartZone(90, 95,  Color(0x33FFA726)),
      ChartZone(95, 101, Color(0x225E35B1)),
    ],
  ),

  'steps': BiomarkerConfig(
    type:           'steps',
    label:          'Steps',
    unitShort:      'steps',
    emoji:          '👟',
    accentColor:    Color(0xFF43A047),
    chartLineColor: Color(0xFF66BB6A),
    chartBgColor:   Color(0xFFF1F8E9),
    isDark:         false,
    minY:  0,
    maxY:  null,
  ),
};
