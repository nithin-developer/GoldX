import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signalpro/app/config/api_config.dart';
import 'package:signalpro/app/services/api_exception.dart';

class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.pendingDeposits,
    required this.pendingWithdrawals,
  });

  static const WalletSummary empty = WalletSummary(
    balance: 0,
    pendingDeposits: 0,
    pendingWithdrawals: 0,
  );

  final double balance;
  final double pendingDeposits;
  final double pendingWithdrawals;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) => double.tryParse(value.toString()) ?? 0;

    return WalletSummary(
      balance: parseNum(json['balance']),
      pendingDeposits: parseNum(json['pending_deposits']),
      pendingWithdrawals: parseNum(json['pending_withdrawals']),
    );
  }
}

class DepositWalletDetails {
  const DepositWalletDetails({
    required this.currency,
    required this.network,
    required this.walletAddress,
    required this.instructions,
    required this.qrCodeUrl,
  });

  final String currency;
  final String? network;
  final String? walletAddress;
  final String? instructions;
  final String? qrCodeUrl;

  factory DepositWalletDetails.fromJson(Map<String, dynamic> json) {
    final resolvedQrCodeUrl = _resolveUrl(json['qr_code_url'] as String?);

    return DepositWalletDetails(
      currency: (json['currency'] as String? ?? 'USDT').toUpperCase(),
      network: (json['network'] as String?)?.trim(),
      walletAddress: (json['wallet_address'] as String?)?.trim(),
      instructions: (json['instructions'] as String?)?.trim(),
      qrCodeUrl: resolvedQrCodeUrl,
    );
  }

  static String? _resolveUrl(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(normalized);
    if (parsed != null && parsed.hasScheme) {
      return normalized;
    }

    return Uri.parse(ApiConfig.baseUrl).resolve(normalized).toString();
  }
}

class DepositRequestResult {
  const DepositRequestResult({
    required this.id,
    required this.status,
    required this.amount,
  });

  final String id;
  final String status;
  final double amount;

  factory DepositRequestResult.fromJson(Map<String, dynamic> json) {
    return DepositRequestResult(
      id: (json['id'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
    );
  }
}

class WithdrawalRequestResult {
  const WithdrawalRequestResult({
    required this.id,
    required this.status,
    required this.amount,
  });

  final String id;
  final String status;
  final double amount;

  factory WithdrawalRequestResult.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestResult(
      id: (json['id'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      amount: double.tryParse(json['amount'].toString()) ?? 0,
    );
  }
}

class WalletApi {
  const WalletApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<WalletSummary> getWalletSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/wallet');
      return WalletSummary.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<DepositWalletDetails> getDepositWalletDetails() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/wallet/deposit-settings');
      return DepositWalletDetails.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<DepositRequestResult> createDeposit({
    required double amount,
    required XFile paymentProof,
    String? transactionRef,
  }) async {
    final proofBytes = await paymentProof.readAsBytes();
    final payload = FormData.fromMap({
      'amount': amount,
      if (transactionRef != null && transactionRef.trim().isNotEmpty)
        'transaction_ref': transactionRef.trim(),
      'payment_proof': MultipartFile.fromBytes(
        proofBytes,
        filename: paymentProof.name,
      ),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/wallet/deposit',
        data: payload,
        options: Options(
          contentType: kIsWeb ? Headers.multipartFormDataContentType : null,
        ),
      );
      return DepositRequestResult.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<WithdrawalRequestResult> createWithdrawal({
    required double amount,
    required String withdrawalPassword,
    String? walletAddress,
  }) async {
    final payload = <String, dynamic>{
      'amount': amount,
      'withdrawal_password': withdrawalPassword,
      if (walletAddress != null && walletAddress.trim().isNotEmpty)
        'wallet_address': walletAddress.trim(),
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>('/wallet/withdraw', data: payload);
      return WithdrawalRequestResult.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

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
