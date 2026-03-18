import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../shared/models/alert.dart';
import '../biomarkers/biomarker_detail_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DashboardBody(state: ref.watch(dashboardProvider));
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  final AsyncValue<DashboardData> state;
  const _DashboardBody({required this.state});

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _tab == 0 ? _buildSummary() : const ChatbotScreen(),
      bottomNavigationBar: _buildNav(),
    );
  }

  // ── Summary tab ─────────────────────────────────────────────────────────────
  Widget _buildSummary() {
    return SafeArea(
      child: widget.state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text('$e',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(dashboardProvider.notifier).load(),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).load(),
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 20),
              _buildHeader(data),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Favourites',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _TappableCard(
                onTap: () => _goToDetail('steps'),
                child: _ActivityCard(readings: data.readings),
              ),
              const SizedBox(height: 12),
              _TappableCard(
                onTap: () => _goToDetail('heart_rate'),
                child: _BiomarkerCard(
                  emoji: '❤️',
                  label: 'Heart Rate',
                  labelColor: AppColors.heartRed,
                  value: data.readings['heart_rate'],
                  unit: 'BPM',
                ),
              ),
              const SizedBox(height: 12),
              _TappableCard(
                onTap: () => _goToDetail('blood_pressure_sys'),
                child: _BiomarkerCard(
                  emoji: '🩸',
                  label: 'Blood Pressure',
                  labelColor: AppColors.blue,
                  value: data.readings['blood_pressure_sys'],
                  value2: data.readings['blood_pressure_dia'],
                  unit: 'mmHg',
                  tappable: true,
                ),
              ),
              const SizedBox(height: 12),
              _TappableCard(
                onTap: () => _goToDetail('blood_glucose'),
                child: _BiomarkerCard(
                  emoji: '💉',
                  label: 'Blood Glucose Level',
                  labelColor: const Color(0xFF00897B),
                  value: data.readings['blood_glucose'],
                  unit: 'mmol/L',
                ),
              ),
              const SizedBox(height: 12),
              _TappableCard(
                onTap: () => _goToDetail('oxygen_saturation'),
                child: _BiomarkerCard(
                  emoji: '🫁',
                  label: 'Oxygen Saturation',
                  labelColor: const Color(0xFF5E35B1),
                  value: data.readings['oxygen_saturation'],
                  unit: 'SpO₂  %',
                ),
              ),
              const SizedBox(height: 12),
              _ManualInputButton(),
              const SizedBox(height: 20),
              if (data.alerts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text('Recent Alerts',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...data.alerts.take(3).map((a) => _AlertTile(alert: a)),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _goToDetail(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BiomarkerDetailScreen(biomarkerType: type),
      ),
    );
  }

  // ── Header — title + last updated + avatar ───────────────────────────────────
  Widget _buildHeader(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // top row: title + avatar
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // tap avatar to go to profile
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfileScreen()),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                          border: Border.all(
                              color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.grey, size: 28),
                      ),
                      const SizedBox(height: 4),
                      const Text('Edit',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.blue)),
                    ],
                  ),
                  // unread alert badge
                  if (data.unreadAlerts > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.critical,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${data.unreadAlerts}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // last updated line — sits below the title row
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(
            'Updated ${_timeAgo(data.lastFetched)}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // ── Bottom nav ───────────────────────────────────────────────────────────────
  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.favorite,
                label: 'Summary',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _NavItem(
                icon: Icons.smart_toy_outlined,
                label: 'Chat Bot',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tappable card wrapper ─────────────────────────────────────────────────────
class _TappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TappableCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: child);
  }
}

// ── Activity card ─────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final Map<String, double?> readings;
  const _ActivityCard({required this.readings});

  @override
  Widget build(BuildContext context) {
    final steps = readings['steps']?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🔥', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('Activity',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.activityOrange)),
            Spacer(),
            Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _Stat('Move',
                '${(steps * 0.04).toStringAsFixed(0)} cal',
                AppColors.heartRed),
            _vDivider(),
            _Stat('Steps', '$steps', AppColors.primary),
            _vDivider(),
            _Stat(
                'SpO₂',
                '${readings['oxygen_saturation']?.toStringAsFixed(0) ?? '--'}%',
                AppColors.blue),
          ]),
        ],
      ),
    );
  }
}

// ── Biomarker card ────────────────────────────────────────────────────────────
class _BiomarkerCard extends StatelessWidget {
  final String emoji, label, unit;
  final Color labelColor;
  final double? value, value2;
  final bool tappable;

  const _BiomarkerCard({
    required this.emoji,
    required this.label,
    required this.labelColor,
    required this.unit,
    this.value,
    this.value2,
    this.tappable = false,
  });

  @override
  Widget build(BuildContext context) {
    String display;
    if (value == null) {
      display = '--';
    } else if (value2 != null) {
      display =
          '${value!.toStringAsFixed(0)}/${value2!.toStringAsFixed(0)}';
    } else {
      display = value! % 1 == 0
          ? value!.toStringAsFixed(0)
          : value!.toStringAsFixed(1);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: labelColor)),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
          ]),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(display,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text(unit,
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Manual input ──────────────────────────────────────────────────────────────
class _ManualInputButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _show(context, ref),
      icon: const Icon(Icons.add, color: AppColors.primary),
      label: const Text('Add manual reading',
          style: TextStyle(color: AppColors.primary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _show(BuildContext context, WidgetRef ref) {
    final types = [
      'heart_rate', 'blood_pressure_sys', 'blood_pressure_dia',
      'blood_glucose', 'oxygen_saturation', 'steps'
    ];
    String selected = types[0];
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Reading',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selected,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  labelText: 'Biomarker type',
                ),
                items: types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.replaceAll('_', ' ')),
                        ))
                    .toList(),
                onChanged: (v) => setS(() => selected = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final val = double.tryParse(ctrl.text);
                    if (val == null) return;
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(dashboardProvider.notifier)
                          .submitManualReading(selected, val);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert tile ────────────────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final Alert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color =
        alert.isCritical ? AppColors.critical : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(
            alert.isCritical
                ? Icons.warning_rounded
                : Icons.info_outline,
            color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(alert.message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary)),
        ),
      ]),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.blue : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal)),
      ]),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      );
}

Widget _vDivider() => Container(
    height: 36,
    width: 1,
    color: const Color(0xFFEEEEEE),
    margin: const EdgeInsets.symmetric(horizontal: 16));

BoxDecoration _cardDecor() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
    );

// ── Time ago helper ───────────────────────────────────────────────────────────
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt).inSeconds;
  if (diff < 10)  return 'just now';
  if (diff < 60)  return '${diff}s ago';
  if (diff < 120) return '1 min ago';
  return '${diff ~/ 60} mins ago';
}
