import 'dart:math';
import '../../../core/services/logger_service.dart';
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

    return otp == _generatedOtp;
  }
}
