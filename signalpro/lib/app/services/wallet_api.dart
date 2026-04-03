import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signalpro/app/config/api_config.dart';
import 'package:signalpro/app/services/api_exception.dart';

String? _resolveApiUrl(String? value) {
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

DateTime _parseDate(dynamic value) {
  final raw = value?.toString();
  final parsed = raw == null ? null : DateTime.tryParse(raw);
  return parsed?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
}

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
    required this.supportUrl,
    required this.qrCodeUrl,
  });

  final String currency;
  final String? network;
  final String? walletAddress;
  final String? instructions;
  final String? supportUrl;
  final String? qrCodeUrl;

  factory DepositWalletDetails.fromJson(Map<String, dynamic> json) {
    final resolvedQrCodeUrl = _resolveApiUrl(json['qr_code_url'] as String?);

    return DepositWalletDetails(
      currency: (json['currency'] as String? ?? 'USDT').toUpperCase(),
      network: (json['network'] as String?)?.trim(),
      walletAddress: (json['wallet_address'] as String?)?.trim(),
      instructions: (json['instructions'] as String?)?.trim(),
      supportUrl: (json['support_url'] as String?)?.trim(),
      qrCodeUrl: resolvedQrCodeUrl,
    );
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

class DepositHistoryRecord {
  const DepositHistoryRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.transactionRef,
    required this.paymentProofUrl,
    required this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final double amount;
  final String status;
  final String? transactionRef;
  final String? paymentProofUrl;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory DepositHistoryRecord.fromJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['updated_at'];
    return DepositHistoryRecord(
      id: (json['id'] as String? ?? '').trim(),
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      transactionRef: (json['transaction_ref'] as String?)?.trim(),
      paymentProofUrl: _resolveApiUrl(json['payment_proof_url'] as String?),
      adminNote: (json['admin_note'] as String?)?.trim(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: updatedAtRaw == null ? null : _parseDate(updatedAtRaw),
    );
  }
}

class WithdrawalHistoryRecord {
  const WithdrawalHistoryRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.walletAddress,
    required this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final double amount;
  final String status;
  final String? walletAddress;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory WithdrawalHistoryRecord.fromJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['updated_at'];
    return WithdrawalHistoryRecord(
      id: (json['id'] as String? ?? '').trim(),
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      walletAddress: (json['wallet_address'] as String?)?.trim(),
      adminNote: (json['admin_note'] as String?)?.trim(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: updatedAtRaw == null ? null : _parseDate(updatedAtRaw),
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
      final response = await _dio.get<Map<String, dynamic>>(
        '/wallet/deposit-settings',
      );
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

  Future<List<DepositHistoryRecord>> getDepositHistory({
    int skip = 0,
    int limit = 50,
    String? status,
  }) async {
    final query = <String, dynamic>{
      'skip': skip,
      'limit': limit,
      if (status != null && status.trim().isNotEmpty)
        'status': status.trim().toLowerCase(),
    };

    try {
      final response = await _dio.get<List<dynamic>>(
        '/wallet/deposits',
        queryParameters: query,
      );
      final items = response.data ?? const <dynamic>[];
      return items
          .map(
            (item) => DepositHistoryRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<DepositHistoryRecord> getDepositDetails(String depositId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/wallet/deposits/$depositId',
      );
      return DepositHistoryRecord.fromJson(response.data ?? const {});
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
      final response = await _dio.post<Map<String, dynamic>>(
        '/wallet/withdraw',
        data: payload,
      );
      return WithdrawalRequestResult.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<WithdrawalHistoryRecord>> getWithdrawalHistory({
    int skip = 0,
    int limit = 50,
    String? status,
  }) async {
    final query = <String, dynamic>{
      'skip': skip,
      'limit': limit,
      if (status != null && status.trim().isNotEmpty)
        'status': status.trim().toLowerCase(),
    };

    try {
      final response = await _dio.get<List<dynamic>>(
        '/wallet/withdrawals',
        queryParameters: query,
      );
      final items = response.data ?? const <dynamic>[];
      return items
          .map(
            (item) => WithdrawalHistoryRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<WithdrawalHistoryRecord> getWithdrawalDetails(
    String withdrawalId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/wallet/withdrawals/$withdrawalId',
      );
      return WithdrawalHistoryRecord.fromJson(response.data ?? const {});
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
      if (currentWithdrawalPassword != null &&
          currentWithdrawalPassword.trim().isNotEmpty)
        'current_withdrawal_password': currentWithdrawalPassword,
    };

    try {
      await _dio.post<void>('/wallet/set-withdrawal-password', data: payload);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
