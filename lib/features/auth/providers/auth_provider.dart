import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/mock_auth_service.dart';
import '../services/auth_service_impl.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  // Set to false to use the real API gateway backend
  final bool useMock = false;
  return useMock ? MockAuthService() : AuthServiceImpl();
});

/// Authentication State
class AuthState {
  final bool isLoading;
  final String phoneNumber;

  const AuthState({this.isLoading = false, this.phoneNumber = ''});

  AuthState copyWith({bool? isLoading, String? phoneNumber}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

/// Authentication Controller
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true);

    final success = await _authService.sendOtp(phone);

    state = state.copyWith(isLoading: false, phoneNumber: phone);

    return success;
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true);

    final success = await _authService.verifyOtp(
      phone: state.phoneNumber,
      otp: otp,
    );

    state = state.copyWith(isLoading: false);

    return success;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await SecureStorageService.clearTokens();
    state = const AuthState();
  }
}

/// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

