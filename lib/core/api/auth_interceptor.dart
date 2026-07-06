import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../../app/constants.dart';
import '../services/logger_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check if error is 401 (Unauthorized)
    if (err.response?.statusCode == 401) {
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          LoggerService.logger.i("Token expired. Attempting refresh...");

          // Call the refresh token endpoint
          final response = await _refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data;
            final newAccessToken = data['access_token'] as String?;
            final newRefreshToken = data['refresh_token'] as String?;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await SecureStorageService.saveAccessToken(newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await SecureStorageService.saveRefreshToken(newRefreshToken);
              }

              LoggerService.logger.i("Token refreshed successfully.");

              // Retry the original request
              final requestOptions = err.requestOptions;
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              // Create a temporary Dio to retry the request
              final retryDio = Dio(BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
              ));

              final retryResponse = await retryDio.request(
                requestOptions.path,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
                options: Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                ),
              );

              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          LoggerService.logger.e("Token refresh failed: $e. Logging out user...");
          await SecureStorageService.clearTokens();
          // Optionally, redirect to login or notify app state here
        }
      } else {
        LoggerService.logger.w("No refresh token found. User must re-authenticate.");
        await SecureStorageService.clearTokens();
      }
    }

    return handler.next(err);
  }
}
