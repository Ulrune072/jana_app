import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../shared/models/alert.dart';
import '../biomarkers/biomarker_detail_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _tab == 0 ? _SummaryTab() : const ChatbotScreen(),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() => Container(
    decoration: BoxDecoration(color: AppColors.navBg,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, -2))]),
    child: SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavItem(icon: Icons.favorite,          label: 'Summary',  selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
        _NavItem(icon: Icons.smart_toy_outlined, label: 'Chat Bot', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
      ]),
    )),
  );
}

// ─── Summary Tab ──────────────────────────────────────────────────────────────
class _SummaryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    return SafeArea(child: state.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 48),
        const SizedBox(height: 12),
        Text('$e', style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => ref.read(dashboardProvider.notifier).load(),
            child: const Text('Retry')),
      ])),
      data: (data) => RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        color: AppColors.primary,
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
          const SizedBox(height: 20),
          _buildHeader(context, data),
          const SizedBox(height: 16),
          const Padding(padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Favourites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          _ActivityCard(readings: data.readings),
          const SizedBox(height: 12),

          // each card navigates to its detail screen
          _TappableBioCard(
            icon: '❤️', label: 'Heart Rate', labelColor: AppColors.heartRed,
            value: data.readings['heart_rate'], unit: 'BPM',
            onTap: () => _goDetail(context, 'heart_rate'),
          ),
          const SizedBox(height: 12),
          _TappableBioCard(
            icon: '🩺', label: 'Blood Pressure', labelColor: AppColors.blue,
            value: data.readings['blood_pressure_sys'],
            value2: data.readings['blood_pressure_dia'], unit: 'mmHg',
            onTap: () => _goDetail(context, 'blood_pressure_sys'),
          ),
          const SizedBox(height: 12),
          _TappableBioCard(
            icon: '💉', label: 'Blood Glucose Level', labelColor: AppColors.activityOrange,
            value: data.readings['blood_glucose'], unit: 'mmol/L',
            onTap: () => _goDetail(context, 'blood_glucose'),
          ),
          const SizedBox(height: 12),
          _TappableBioCard(
            icon: '🫁', label: 'Oxygen Saturation', labelColor: AppColors.heartRed,
            value: data.readings['oxygen_saturation'], unit: 'SpO₂  %',
            onTap: () => _goDetail(context, 'oxygen_saturation'),
          ),
          const SizedBox(height: 12),
          _TappableBioCard(
            icon: '👟', label: 'Steps', labelColor: const Color(0xFF9C27B0),
            value: data.readings['steps'], unit: 'steps',
            onTap: () => _goDetail(context, 'steps'),
          ),
          const SizedBox(height: 12),
          _ManualInputButton(),
          const SizedBox(height: 20),
          if (data.alerts.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('Recent Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ...data.alerts.take(3).map((a) => _AlertTile(alert: a)),
            const SizedBox(height: 20),
          ],
        ]),
      ),
    ));
  }

  void _goDetail(BuildContext context, String type) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BiomarkerDetailScreen(biomarkerType: type)));
  }

  Widget _buildHeader(BuildContext context, DashboardData data) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Summary', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
      const Spacer(),
      Stack(children: [
        GestureDetector(
          // tapping avatar/Edit opens profile screen
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade300,
                  border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.person, color: Colors.grey, size: 28),
            ),
            const SizedBox(height: 4),
            const Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.blue)),
          ]),
        ),
        if (data.unreadAlerts > 0)
          Positioned(right: 0, top: 0,
            child: Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(color: AppColors.critical, shape: BoxShape.circle),
              child: Center(child: Text('${data.unreadAlerts}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            )),
      ]),
    ]);
  }
}

// ─── Tappable biomarker card ──────────────────────────────────────────────────
class _TappableBioCard extends StatelessWidget {
  final String icon, label, unit;
  final Color labelColor;
  final double? value, value2;
  final VoidCallback onTap;

  const _TappableBioCard({
    required this.icon, required this.label, required this.labelColor,
    required this.unit, required this.onTap, this.value, this.value2,
  });

  @override
  Widget build(BuildContext context) {
    String display;
    if (value == null)       display = '--';
    else if (value2 != null) display = '${value!.toStringAsFixed(0)}/${value2!.toStringAsFixed(0)}';
    else                     display = value! % 1 == 0 ? value!.toStringAsFixed(0) : value!.toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: labelColor)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(display, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text(unit, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Activity card ────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final Map<String, double?> readings;
  const _ActivityCard({required this.readings});
  @override
  Widget build(BuildContext context) {
    final steps = readings['steps']?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('🔥', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.activityOrange)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _Stat(label: 'Move',  value: '${(steps * 0.04).toStringAsFixed(0)} cal', color: AppColors.heartRed),
          _vDivider(), _Stat(label: 'Steps', value: '$steps',                      color: AppColors.primary),
          _vDivider(), _Stat(label: 'SpO₂',  value: '${readings['oxygen_saturation']?.toStringAsFixed(0) ?? '--'}%', color: AppColors.blue),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
  ]);
}

Widget _vDivider() => Container(height: 36, width: 1, color: const Color(0xFFEEEEEE), margin: const EdgeInsets.symmetric(horizontal: 16));

// ─── Manual Input ─────────────────────────────────────────────────────────────
class _ManualInputButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _show(context, ref),
      icon: const Icon(Icons.add, color: AppColors.primary),
      label: const Text('Add manual reading', style: TextStyle(color: AppColors.primary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _show(BuildContext context, WidgetRef ref) {
    const types = ['heart_rate','blood_pressure_sys','blood_pressure_dia','blood_glucose','oxygen_saturation','steps'];
    String sel = types[0];
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(builder: (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Reading', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: sel,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), labelText: 'Biomarker type'),
            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_',' ')))).toList(),
            onChanged: (v) => setS(() => sel = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Value', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val == null) return;
              Navigator.pop(ctx);
              try {
                await ref.read(dashboardProvider.notifier).submitManualReading(sel, val);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Save'),
          )),
        ])),
      ),
    );
  }
}

// ─── Alert tile ───────────────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final Alert alert;
  const _AlertTile({required this.alert});
  @override
  Widget build(BuildContext context) {
    final color = alert.isCritical ? AppColors.critical : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(alert.isCritical ? Icons.warning_rounded : Icons.info_outline, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(alert.message, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

// ─── Nav item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.textSecondary;
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 26),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
    ]));
  }
}
