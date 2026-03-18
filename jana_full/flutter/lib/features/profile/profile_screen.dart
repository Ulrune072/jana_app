import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import 'profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _doctorCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  String? _selectedGender;
  bool _editMode = false;
  bool _populated = false;

  static const _genders = ['male','female','other','prefer_not_to_say'];
  static const _genderLabels = {
    'male':'Male','female':'Female','other':'Other','prefer_not_to_say':'Prefer not to say',
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController();
    _dobCtrl    = TextEditingController();
    _doctorCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _dobCtrl.dispose(); _doctorCtrl.dispose();
    _heightCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }

  void _populate(dynamic profile) {
    if (_populated || profile == null) return;

    _nameCtrl.text   = profile.fullName;
    _doctorCtrl.text = profile.doctorEmail ?? '';   // was _emailCtrl
    _heightCtrl.text = profile.heightCm != null
        ? profile.heightCm!.toStringAsFixed(0) : '';
    _weightCtrl.text = profile.weightKg != null
        ? profile.weightKg!.toStringAsFixed(0) : '';
    _dobCtrl.text    = profile.dateOfBirth ?? '';   // was _selectedDob
    _selectedGender  = profile.gender;

    _populated = true;
  }

  Future<void> _save() async {
    final fields = <String, dynamic>{};
    if (_nameCtrl.text.trim().isNotEmpty)   fields['full_name']     = _nameCtrl.text.trim();
    if (_dobCtrl.text.trim().isNotEmpty)    fields['date_of_birth'] = _dobCtrl.text.trim();
    if (_doctorCtrl.text.trim().isNotEmpty) fields['doctor_email']  = _doctorCtrl.text.trim();
    final h = double.tryParse(_heightCtrl.text.trim());
    final w = double.tryParse(_weightCtrl.text.trim());
    if (h != null) fields['height_cm'] = h;
    if (w != null) fields['weight_kg'] = w;
    if (_selectedGender != null) fields['gender'] = _selectedGender;
    await ref.read(profileProvider.notifier).save(fields);
    setState(() => _editMode = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365*20)),
      firstDate: DateTime(1920), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    _populate(state.profile);

    ref.listen<ProfileState>(profileProvider, (_, next) {
      if (!_populated && next.profile != null) {
        setState(() => _populate(next.profile!));
      }
      if (next.saved) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile saved'), backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ));
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!), backgroundColor: AppColors.critical,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(slivers: [
              _appBar(state),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  if (state.profile != null) ...[
                    _statsRow(state.profile!),
                    const SizedBox(height: 20),
                  ],
                  _section('Personal Information', Icons.person_outline, [
                    _field('Full name',    _nameCtrl,   Icons.badge_outlined),
                    _dateField(),
                    _genderField(),
                  ]),
                  const SizedBox(height: 16),
                  _section('Body Measurements', Icons.monitor_weight_outlined, [
                    Row(children: [
                      Expanded(child: _field('Height (cm)', _heightCtrl, Icons.height,
                          keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _field('Weight (kg)', _weightCtrl, Icons.scale_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  _section('Medical', Icons.medical_services_outlined, [
                    _field("Doctor's email", _doctorCtrl, Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        hint: 'Alerts will be sent here'),
                    if (!_editMode && (state.profile?.doctorEmail?.isEmpty ?? true))
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          const Text('No doctor email — alerts won\'t be sent',
                              style: TextStyle(fontSize: 12, color: AppColors.warning)),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _editMode
                      ? Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () {
                              if (state.profile != null) _populate(state.profile!);
                              setState(() => _editMode = false);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.textSecondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(
                            onPressed: state.isSaving ? null : _save,
                            child: state.isSaving
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Save changes'),
                          )),
                        ])
                      : SizedBox(width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _editMode = true),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit profile'),
                          )),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      icon: const Icon(Icons.logout, color: AppColors.critical),
                      label: const Text(
                        'Log out',
                        style: TextStyle(color: AppColors.critical),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.critical),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              )),
            ]),
    );
  }

  Widget _appBar(ProfileState state) => SliverAppBar(
    expandedHeight: 200, pinned: true,
    backgroundColor: AppColors.primary,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
    flexibleSpace: FlexibleSpaceBar(
      title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      background: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        )),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 40),
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 8),
          Text(state.profile?.fullName ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
    ),
  );

  Widget _statsRow(p) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _Chip(label: 'Height', value: p.heightDisplay),
      Container(height: 44, width: 1, color: const Color(0xFFEEEEEE)),
      _Chip(label: 'Weight', value: p.weightDisplay),
      Container(height: 44, width: 1, color: const Color(0xFFEEEEEE)),
      _Chip(label: 'BMI', value: p.bmiDisplay, sub: p.bmiLabel),
    ]),
  );

  Widget _section(String title, IconData icon, List<Widget> children) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const SizedBox(height: 16),
      ...children,
    ]),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon, {
    TextInputType keyboardType = TextInputType.text, String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl, enabled: _editMode, keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _editMode ? AppColors.primary : AppColors.textHint, size: 20),
          hintText: hint,
          filled: true, fillColor: _editMode ? Colors.white : const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    ]),
  );

  Widget _dateField() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Date of birth', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: _editMode ? _pickDate : null,
        child: AbsorbPointer(child: TextField(
          controller: _dobCtrl, enabled: _editMode,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today_outlined,
                color: _editMode ? AppColors.primary : AppColors.textHint, size: 20),
            hintText: 'YYYY-MM-DD',
            filled: true, fillColor: _editMode ? Colors.white : const Color(0xFFF8F8F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
            enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
          ),
        )),
      ),
    ]),
  );

  Widget _genderField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Gender', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    const SizedBox(height: 4),
    DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.people_outline,
            color: _editMode ? AppColors.primary : AppColors.textHint, size: 20),
        filled: true, fillColor: _editMode ? Colors.white : const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
        enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEEEEE))),
      ),
      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(_genderLabels[g]!))).toList(),
      onChanged: _editMode ? (v) => setState(() => _selectedGender = v) : null,
    ),
  ]);
}

class _Chip extends StatelessWidget {
  final String label, value;
  final String? sub;
  const _Chip({required this.label, required this.value, this.sub});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    if (sub != null && sub!.isNotEmpty)
      Text(sub!, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
  ]);
}
