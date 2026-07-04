abstract class AuthService {
  Future<bool> sendOtp(String phone);

  Future<bool> verifyOtp({required String phone, required String otp});
}
