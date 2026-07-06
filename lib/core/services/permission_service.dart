import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  static Future<bool> isLocationGranted() async {
    return Permission.location.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> isLocationPermanentlyDenied() async {
    return Permission.location.isPermanentlyDenied;
  }

  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}
