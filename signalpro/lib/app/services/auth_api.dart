import 'package:dio/dio.dart';
import 'package:signalpro/app/config/api_config.dart';
import 'package:signalpro/app/models/auth_tokens.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/services/api_exception.dart';

class AuthApi {
  AuthApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  final Dio _dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthTokens.fromJson(response.data!);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<AuthTokens> register({
    required String email,
    required String password,
    required String inviteCode,
    String? fullName,
    String? phone,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      'invite_code': inviteCode.trim(),
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: payload,
      );
      return AuthTokens.fromJson(response.data!);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> validateInviteCode({required String inviteCode}) async {
    try {
      await _dio.get<void>('/auth/validate-invite/${inviteCode.trim()}');
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<AuthTokens> refreshToken({required String refreshToken}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return AuthTokens.fromJson(response.data!);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UserProfile> getMe({required String accessToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return UserProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<void>(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
