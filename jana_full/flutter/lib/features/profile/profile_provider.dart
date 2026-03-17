import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../shared/models/user_profile.dart';

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool saved;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving  = false,
    this.error,
    this.saved     = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? saved,
  }) => ProfileState(
    profile:   profile   ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    isSaving:  isSaving  ?? this.isSaving,
    error:     error,
    saved:     saved     ?? false,
  );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Dio _api = createApiClient();

  ProfileNotifier() : super(const ProfileState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final res     = await _api.get('/api/profile');
      final profile = UserProfile.fromJson(res.data['profile']);
      state = state.copyWith(isLoading: false, profile: profile);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['error'] ?? 'Failed to load profile',
      );
    }
  }

  Future<void> save(Map<String, dynamic> fields) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final res     = await _api.patch('/api/profile', data: fields);
      final updated = UserProfile.fromJson(res.data['profile']);
      state = state.copyWith(isSaving: false, profile: updated, saved: true);
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.response?.data?['error'] ?? 'Failed to save profile',
      );
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);
