import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/services/logger_service.dart';
import 'auth_service.dart';

class AuthServiceImpl implements AuthService {
  @override
  Future<bool> sendOtp(String phone) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/otp/request',
        data: {'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        LoggerService.logger.i("OTP request sent successfully for: $phone");
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.logger.e("Failed to request OTP: $e");
      return false;
    }
  }

  @override
  Future<bool> verifyOtp({required String phone, required String otp}) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/otp/verify',
        data: {
          'phone': phone,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          await SecureStorageService.saveAccessToken(accessToken);
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await SecureStorageService.saveRefreshToken(refreshToken);
          }
          LoggerService.logger.i("OTP verified successfully and tokens saved.");
          return true;
        }
      }
      return false;
    } catch (e) {
      LoggerService.logger.e("Failed to verify OTP: $e");
      return false;
    }
  }
}
