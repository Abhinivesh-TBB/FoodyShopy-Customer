import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/storage/local_cache.dart';
import '../../../shared/models/saved_address.dart';

class LocationState {
  final double activeLatitude;
  final double activeLongitude;
  final String activeAddressLine;
  final List<SavedAddress> savedAddresses;
  final bool isLoading;
  final bool hasPermission;

  const LocationState({
    this.activeLatitude = 12.9716, // Indiranagar Lat
    this.activeLongitude = 77.6408, // Indiranagar Lng
    this.activeAddressLine = 'HAL 2nd Stage, Indiranagar, Bengaluru, Karnataka 560038',
    this.savedAddresses = const [],
    this.isLoading = false,
    this.hasPermission = false,
  });

  LocationState copyWith({
    double? activeLatitude,
    double? activeLongitude,
    String? activeAddressLine,
    List<SavedAddress>? savedAddresses,
    bool? isLoading,
    bool? hasPermission,
  }) {
    return LocationState(
      activeLatitude: activeLatitude ?? this.activeLatitude,
      activeLongitude: activeLongitude ?? this.activeLongitude,
      activeAddressLine: activeAddressLine ?? this.activeAddressLine,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  static const String _keySavedAddresses = 'key_saved_addresses';

  LocationNotifier() : super(const LocationState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await checkPermissionStatus();
    _loadSavedAddresses();
    state = state.copyWith(isLoading: false);
  }

  Future<void> checkPermissionStatus() async {
    final granted = await PermissionService.isLocationGranted();
    state = state.copyWith(hasPermission: granted);
  }

  void _loadSavedAddresses() {
    try {
      final jsonString = LocalCache.getString(_keySavedAddresses);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(jsonString);
        final list = decodedList.map((e) => SavedAddress.fromJson(e)).toList();
        state = state.copyWith(savedAddresses: list);
      } else {
        // Pre-populate default mock addresses on first load
        final defaults = [
          const SavedAddress(
            label: 'Home 🏠',
            addressLine: 'HAL 2nd Stage, Indiranagar, Bengaluru, Karnataka 560038',
            latitude: 12.9716,
            longitude: 77.6408,
          ),
          const SavedAddress(
            label: 'Work 💼',
            addressLine: '80 Feet Road, Koramangala 4th Block, Bengaluru, Karnataka 560034',
            latitude: 12.9352,
            longitude: 77.6245,
          ),
        ];
        state = state.copyWith(savedAddresses: defaults);
        _saveToCache(defaults);
      }
    } catch (e) {
      // Fallback
    }
  }

  void _saveToCache(List<SavedAddress> list) {
    try {
      final listJson = list.map((e) => e.toJson()).toList();
      LocalCache.setString(_keySavedAddresses, json.encode(listJson));
    } catch (e) {
      // Fallback
    }
  }

  /// Sets the active delivery location
  void selectActiveAddress(String addressLine, double lat, double lng) {
    state = state.copyWith(
      activeAddressLine: addressLine,
      activeLatitude: lat,
      activeLongitude: lng,
    );
  }

  /// Adds a new address to the saved profile list and persists it
  void saveAddress(String label, String addressLine, double lat, double lng) {
    final address = SavedAddress(
      label: label,
      addressLine: addressLine,
      latitude: lat,
      longitude: lng,
    );

    // Filter duplicates by label name
    final list = List<SavedAddress>.from(state.savedAddresses)
      ..removeWhere((e) => e.label.toLowerCase() == label.toLowerCase())
      ..add(address);

    state = state.copyWith(savedAddresses: list);
    _saveToCache(list);
  }

  /// Deletes a saved address profile
  void deleteAddress(String label) {
    final list = List<SavedAddress>.from(state.savedAddresses)
      ..removeWhere((e) => e.label == label);

    state = state.copyWith(savedAddresses: list);
    _saveToCache(list);
  }

  /// Requests permissions and extracts device location details using GPS
  Future<bool> fetchDeviceLocation() async {
    state = state.copyWith(isLoading: true);
    
    // Check and request
    final permissionGranted = await PermissionService.requestLocationPermission();
    state = state.copyWith(hasPermission: permissionGranted);

    if (!permissionGranted) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      final address = await LocationService.reverseGeocode(position.latitude, position.longitude);
      state = state.copyWith(
        activeLatitude: position.latitude,
        activeLongitude: position.longitude,
        activeAddressLine: address,
        isLoading: false,
      );
      return true;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  /// Evaluates query results of places
  List<Map<String, dynamic>> searchAddressSuggestions(String query) {
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();
    
    // Mock places suggestions list
    final List<Map<String, dynamic>> places = [
      {'name': 'HAL 2nd Stage, Indiranagar, Bengaluru', 'lat': 12.9716, 'lng': 77.6408},
      {'name': '100 Feet Road, Indiranagar, Bengaluru', 'lat': 12.9721, 'lng': 77.6385},
      {'name': '80 Feet Road, Koramangala 4th Block, Bengaluru', 'lat': 12.9352, 'lng': 77.6245},
      {'name': 'ITPL Main Road, Whitefield, Bengaluru', 'lat': 12.9698, 'lng': 77.7499},
      {'name': 'Sector 4, HSR Layout, Bengaluru', 'lat': 12.9103, 'lng': 77.6450},
      {'name': 'Sector 7, HSR Layout, Bengaluru', 'lat': 12.9080, 'lng': 77.6402},
      {'name': 'MG Road Metro Station, Bengaluru', 'lat': 12.9740, 'lng': 77.6074},
      {'name': 'Brigade Road, Ashok Nagar, Bengaluru', 'lat': 12.9710, 'lng': 77.6070},
    ];

    return places
        .where((e) => (e['name'] as String).toLowerCase().contains(q))
        .toList();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
