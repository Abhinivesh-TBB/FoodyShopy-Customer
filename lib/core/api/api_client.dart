import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../app/constants.dart';
import 'auth_interceptor.dart';
import 'mock_api_interceptor.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            sendTimeout: AppConstants.connectTimeout,
            responseType: ResponseType.json,
            headers: const {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.addAll([
          if (AppConstants.useMockApi) MockApiInterceptor(),

          AuthInterceptor(),

          if (kDebugMode)
            LogInterceptor(
              requestHeader: true,
              requestBody: true,
              responseHeader: false,
              responseBody: true,
              error: true,
            ),
        ]);
}
