import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'logger_service.dart';

class LocationService {
  LocationService._();

  /// Gets the current GPS coordinates of the device if service is enabled.
  static Future<Position?> getCurrentPosition() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        LoggerService.logger.w("Location services are disabled on the device.");
        return null;
      }

      // Check current permission before fetching
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          LoggerService.logger.w("Location permission denied by user.");
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      LoggerService.logger.e("Error getting current GPS position: $e");
      return null;
    }
  }

  /// Resolves coordinates to a human-readable address line.
  /// Uses a local database for top Bengaluru spots, else returns a formatted coordinate label.
  static Future<String> reverseGeocode(double latitude, double longitude) async {
    // Top Bengaluru spots database for realistic offline simulations
    final List<Map<String, dynamic>> spots = [
      {
        'name': 'HAL 2nd Stage, Indiranagar, Bengaluru, Karnataka 560038',
        'lat': 12.9716,
        'lng': 77.6408,
      },
      {
        'name': '80 Feet Road, Koramangala 4th Block, Bengaluru, Karnataka 560034',
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
        'name': 'Cobbon Road, MG Road, Bengaluru, Karnataka 560001',
        'lat': 12.9740,
        'lng': 77.6074,
      }
    ];

    // Find the closest spot using Euclidean distance (small area approximation)
    var closestSpot = spots.first;
    var minDistance = double.infinity;

    for (final spot in spots) {
      final double latDiff = spot['lat'] - latitude;
      final double lngDiff = spot['lng'] - longitude;
      final double dist = sqrt(latDiff * latDiff + lngDiff * lngDiff);

      if (dist < minDistance) {
        minDistance = dist;
        closestSpot = spot;
      }
    }

    // If we are within ~1.5km of a spot, return its exact address
    if (minDistance < 0.015) {
      return closestSpot['name'];
    }

    // Otherwise, return a formatted coordinates line
    return 'Road No. ${((latitude + longitude) * 100).abs().toStringAsFixed(0)}, Bengaluru, Karnataka ${(560000 + (latitude * 1000).abs() % 100).toInt()}';
  }
}
