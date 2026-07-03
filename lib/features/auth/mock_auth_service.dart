class MockAuthService {
  Future<bool> sendOtp(String phone) async {
    await Future.delayed(const Duration(seconds: 2));

    return true;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    await Future.delayed(const Duration(seconds: 2));

    return otp == "123456";
  }
}
