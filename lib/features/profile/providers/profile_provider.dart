import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache.dart';

class ProfileState {
  final String name;
  final String email;
  final String profilePictureUrl;

  // 1. Centralized default constants
  static const String defaultName = 'FoodyShopy Customer';
  static const String defaultEmail = 'customer@foodyshopy.com';

  const ProfileState({
    this.name = defaultName,
    this.email = defaultEmail,
    this.profilePictureUrl = '',
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? profilePictureUrl,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }

  // 2. Added equality overrides to prevent unnecessary UI rebuilds
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileState &&
        other.name == name &&
        other.email == email &&
        other.profilePictureUrl == profilePictureUrl;
  }

  @override
  int get hashCode =>
      name.hashCode ^ email.hashCode ^ profilePictureUrl.hashCode;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  static const String _keyName = 'key_profile_name';
  static const String _keyEmail = 'key_profile_email';

  ProfileNotifier() : super(const ProfileState()) {
    _loadProfile();
  }

  void _loadProfile() {
    try {
      final savedName = LocalCache.getString(_keyName);
      final savedEmail = LocalCache.getString(_keyEmail);

      state = state.copyWith(
        // 3. Added .trim() to ensure empty space strings fall back to defaults
        name: (savedName != null && savedName.trim().isNotEmpty)
            ? savedName
            : ProfileState.defaultName,
        email: (savedEmail != null && savedEmail.trim().isNotEmpty)
            ? savedEmail
            : ProfileState.defaultEmail,
      );
    } catch (e, stackTrace) {
      // 4. Proper error logging instead of swallowing the exception
      debugPrint('Error loading profile: $e\n$stackTrace');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    // Optimistic UI update - updates UI instantly before cache finishes saving
    state = state.copyWith(name: name, email: email);

    try {
      await LocalCache.setString(_keyName, name);
      await LocalCache.setString(_keyEmail, email);
    } catch (e, stackTrace) {
      debugPrint('Error saving profile: $e\n$stackTrace');
      // Note: If you want true resilience, you could revert the state here
      // if the cache fails, but for non-critical user settings, logging is fine.
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});
