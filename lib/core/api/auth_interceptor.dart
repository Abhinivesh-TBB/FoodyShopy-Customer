import 'package:dio/dio.dart';

import '../../app/constants.dart';
import '../services/logger_service.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      responseType: ResponseType.json,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle Unauthorized responses
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await SecureStorageService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      LoggerService.logger.w('No refresh token found. User must log in again.');

      await SecureStorageService.clearTokens();
      return handler.next(err);
    }

    try {
      LoggerService.logger.i('Access token expired. Refreshing token...');

      final response = await _refreshDio.post(
        AppConstants.refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode >= 200 && statusCode < 300) {
        final data = response.data;

        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          throw Exception('Refresh API did not return an access token.');
        }

        await SecureStorageService.saveAccessToken(newAccessToken);

        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await SecureStorageService.saveRefreshToken(newRefreshToken);
        }

        LoggerService.logger.i('Token refreshed successfully.');

        final requestOptions = err.requestOptions;

        requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryDio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            sendTimeout: AppConstants.sendTimeout,
            responseType: ResponseType.json,
          ),
        );

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
    } catch (e, stackTrace) {
      LoggerService.logger.e(
        'Token refresh failed.',
        error: e,
        stackTrace: stackTrace,
      );

      await SecureStorageService.clearTokens();
    }

    return handler.next(err);
  }
}
