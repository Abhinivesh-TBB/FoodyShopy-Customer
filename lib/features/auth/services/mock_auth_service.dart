import 'dart:math';
import '../../../core/services/logger_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  String? _generatedOtp;

  @override
  Future<bool> sendOtp(String phone) async {
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();

    _generatedOtp = (100000 + random.nextInt(900000)).toString();
 
    LoggerService.logger.i("Mock OTP : $_generatedOtp");
    LoggerService.logger.i("Phone : $phone");
    

    return true;
  }

  @override
  Future<bool> verifyOtp({required String phone, required String otp}) async {
    await Future.delayed(const Duration(seconds: 2));

    final success = otp == _generatedOtp || otp == '123456';
    if (success) {
      await SecureStorageService.saveAccessToken('mock_access_token_${DateTime.now().millisecondsSinceEpoch}');
      await SecureStorageService.saveRefreshToken('mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}');
    }
    return success;
  }
}
