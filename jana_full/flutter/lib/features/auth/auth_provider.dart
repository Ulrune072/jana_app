// lib/features/auth/auth_provider.dart
//
// This file holds all the state and logic related to authentication.
// Using Riverpod's StateNotifier means the UI reacts automatically whenever
// auth state changes — no need to call setState() anywhere.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';

// The state object — represents exactly what the auth screens need to know
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess; // true briefly after a successful action

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthState copyWith({bool? isLoading, String? errorMessage, bool? isSuccess}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,     // null clears the error
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _api = createApiClient();

  AuthNotifier() : super(const AuthState());

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      // Step 1: Create the auth account via Supabase
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName}, // this is picked up by the DB trigger
      );

      if (response.user == null) {
        throw Exception('Registration failed — no user returned');
      }

      // Step 2: Save the profile via our Express backend.
      // We call this immediately after sign-up so the profiles table
      // has a row with the correct name before the user reaches the dashboard.
      await _api.post('/api/auth/profile', data: {'full_name': fullName});

      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      // Supabase throws AuthException for things like "email already in use"
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Network error. Is the backend running?';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // On success, Supabase stores the session automatically.
      // The navigation guard in main.dart will detect the new session
      // and redirect to the dashboard.
      print(Supabase.instance.client.auth.currentSession?.accessToken);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// The provider — widgets access auth state via ref.watch(authProvider)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
