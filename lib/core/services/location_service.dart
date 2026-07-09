import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'logger_service.dart';

class LocationService {
  LocationService._();

  // Mock offline locations used during development.
  static const List<Map<String, Object>> _mockLocations = [
    {
      'name': 'HAL 2nd Stage, Indiranagar, Bengaluru, Karnataka 560038',
      'lat': 12.9716,
      'lng': 77.6408,
    },
    {
      'name':
          '80 Feet Road, Koramangala 4th Block, Bengaluru, Karnataka 560034',
      'lat': 12.9352,
      'lng': 77.6245,
    },
    {
      'name': 'ITPL Main Road, Whitefield, Bengaluru, Karnataka 560066',
      'lat': 12.9698,
      'lng': 77.7499,
    },
    {
      'name': 'Sector 4, HSR Layout, Bengaluru, Karnataka 560102',
      'lat': 12.9103,
      'lng': 77.6450,
    },
    {
      'name': 'Cubbon Road, MG Road, Bengaluru, Karnataka 560001',
      'lat': 12.9740,
      'lng': 77.6074,
    },
  ];

  /// Returns the current device location.
  ///
  /// Returns `null` if:
  /// - Location services are disabled.
  /// - Permission is denied.
  /// - An error occurs while fetching the location.
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        LoggerService.logger.w('Location services are disabled.');
        return null;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        LoggerService.logger.w('Location permission denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e, stackTrace) {
      LoggerService.logger.e(
        'Failed to get current location.',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Returns a mock address based on the nearest known location.
  ///
  /// This is intended for development only.
  /// Replace this with the `geocoding` package when connecting
  /// to a real backend.
  static Future<String> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    var closestLocation = _mockLocations.first;
    var shortestDistance = double.infinity;

    for (final location in _mockLocations) {
      final lat = (location['lat'] as num).toDouble();

      final lng = (location['lng'] as num).toDouble();

      final distance = sqrt(pow(lat - latitude, 2) + pow(lng - longitude, 2));

      if (distance < shortestDistance) {
        shortestDistance = distance;
        closestLocation = location;
      }
    }

    // Approximately within 1.5 km.
    if (shortestDistance < 0.015) {
      return closestLocation['name'] as String;
    }

    final pin = ((latitude + longitude) * 100).abs().round();

    final pincode = 560000 + ((latitude * 1000).abs() % 100).toInt();

    return 'Road No. $pin, Bengaluru, Karnataka $pincode';
  }
}
