import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  /// Returns true if the given permission is granted.
  static Future<bool> isGranted(Permission permission) async {
    return permission.isGranted;
  }

  /// Requests the given permission.
  /// Returns true if permission is granted.
  static Future<bool> request(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  /// Returns true if the permission is permanently denied.
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    return permission.isPermanentlyDenied;
  }

  /// Opens the application settings page.
  static Future<bool> openSettings() {
    return openAppSettings();
  }

  // ==========================
  // Convenience Methods
  // ==========================

  static Future<bool> isLocationGranted() => isGranted(Permission.location);

  static Future<bool> requestLocationPermission() =>
      request(Permission.location);

  static Future<bool> isLocationPermanentlyDenied() =>
      isPermanentlyDenied(Permission.location);

  static Future<bool> isNotificationGranted() =>
      isGranted(Permission.notification);

  static Future<bool> requestNotificationPermission() =>
      request(Permission.notification);

  static Future<bool> isCameraGranted() => isGranted(Permission.camera);

  static Future<bool> requestCameraPermission() => request(Permission.camera);
}
