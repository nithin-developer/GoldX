import 'package:dio/dio.dart';
import 'package:signalpro/app/config/api_config.dart';

abstract class AuthSessionDelegate {
  String? get accessToken;
  Future<bool> refreshAccessToken();
  Future<void> handleSessionExpired();
}

class ApiClient {
  ApiClient({required AuthSessionDelegate authSessionDelegate})
      : _authSessionDelegate = authSessionDelegate,
        dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authSessionDelegate.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (statusCode == 401 && !alreadyRetried) {
            final refreshed = await _authSessionDelegate.refreshAccessToken();

            if (refreshed) {
              final retryOptions = error.requestOptions;
              retryOptions.extra['retried'] = true;

              final token = _authSessionDelegate.accessToken;
              if (token != null && token.isNotEmpty) {
                retryOptions.headers['Authorization'] = 'Bearer $token';
              }

              try {
                final response = await dio.fetch<dynamic>(retryOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }

            await _authSessionDelegate.handleSessionExpired();
          }

          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final AuthSessionDelegate _authSessionDelegate;
}
