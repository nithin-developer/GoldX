import 'package:dio/dio.dart';
import 'package:signalpro/app/services/api_exception.dart';

class WalletApi {
  const WalletApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> setOrUpdateWithdrawalPassword({
    required String newWithdrawalPassword,
    String? currentWithdrawalPassword,
  }) async {
    final payload = <String, dynamic>{
      'new_withdrawal_password': newWithdrawalPassword,
      if (currentWithdrawalPassword != null && currentWithdrawalPassword.trim().isNotEmpty)
        'current_withdrawal_password': currentWithdrawalPassword,
    };

    try {
      await _dio.post<void>('/wallet/set-withdrawal-password', data: payload);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
