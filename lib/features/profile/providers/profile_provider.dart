import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache.dart';

class ProfileState {
  final String name;
  final String email;
  final String profilePictureUrl;

  const ProfileState({
    this.name = 'FoodyShopy Customer',
    this.email = 'customer@foodyshopy.com',
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
        name: savedName != null && savedName.isNotEmpty ? savedName : 'FoodyShopy Customer',
        email: savedEmail != null && savedEmail.isNotEmpty ? savedEmail : 'customer@foodyshopy.com',
      );
    } catch (_) {
      // Fallback
    }
  }

  Future<void> updateProfile({required String name, required String email}) async {
    state = state.copyWith(name: name, email: email);
    try {
      await LocalCache.setString(_keyName, name);
      await LocalCache.setString(_keyEmail, email);
    } catch (_) {
      // Fallback
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
