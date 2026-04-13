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

DateTime? _parseNullableDate(dynamic value) {
  if (value == null) {
    return null;
  }
  final raw = value.toString().trim();
  if (raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw)?.toLocal();
}

double _parseNum(dynamic value) => double.tryParse(value.toString()) ?? 0;

int _parseInt(dynamic value) => int.tryParse(value.toString()) ?? 0;

class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.capitalBalance,
    required this.signalProfitBalance,
    required this.rewardBalance,
    required this.withdrawableBalance,
    required this.lockedCapitalBalance,
    required this.unlockedCapitalBalance,
    required this.capitalLockActive,
    required this.capitalLockEndsAt,
    required this.capitalLockDaysRemaining,
    required this.withdrawalFeePercent,
    required this.withdrawalFeeNotice,
    required this.pendingDeposits,
    required this.pendingWithdrawals,
  });

  static const WalletSummary empty = WalletSummary(
    balance: 0,
    capitalBalance: 0,
    signalProfitBalance: 0,
    rewardBalance: 0,
    withdrawableBalance: 0,
    lockedCapitalBalance: 0,
    unlockedCapitalBalance: 0,
    capitalLockActive: false,
    capitalLockEndsAt: null,
    capitalLockDaysRemaining: 0,
    withdrawalFeePercent: 10,
    withdrawalFeeNotice:
        '10% withdrawal fee will be deducted from any withdrawal',
    pendingDeposits: 0,
    pendingWithdrawals: 0,
  );

  final double balance;
  final double capitalBalance;
  final double signalProfitBalance;
  final double rewardBalance;
  final double withdrawableBalance;
  final double lockedCapitalBalance;
  final double unlockedCapitalBalance;
  final bool capitalLockActive;
  final DateTime? capitalLockEndsAt;
  final int capitalLockDaysRemaining;
  final double withdrawalFeePercent;
  final String withdrawalFeeNotice;
  final double pendingDeposits;
  final double pendingWithdrawals;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balance: _parseNum(json['balance']),
      capitalBalance: _parseNum(json['capital_balance']),
      signalProfitBalance: _parseNum(json['signal_profit_balance']),
      rewardBalance: _parseNum(json['reward_balance']),
      withdrawableBalance: _parseNum(json['withdrawable_balance']),
      lockedCapitalBalance: _parseNum(json['locked_capital_balance']),
      unlockedCapitalBalance: _parseNum(json['unlocked_capital_balance']),
      capitalLockActive: json['capital_lock_active'] == true,
      capitalLockEndsAt: _parseNullableDate(json['capital_lock_ends_at']),
      capitalLockDaysRemaining: _parseInt(json['capital_lock_days_remaining']),
      withdrawalFeePercent: _parseNum(json['withdrawal_fee_percent']),
      withdrawalFeeNotice:
          (json['withdrawal_fee_notice'] as String? ??
                  '10% withdrawal fee will be deducted from any withdrawal')
              .trim(),
      pendingDeposits: _parseNum(json['pending_deposits']),
      pendingWithdrawals: _parseNum(json['pending_withdrawals']),
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
    required this.selfRewardAmount,
    required this.referrerRewardAmount,
  });

  final String id;
  final String status;
  final double amount;
  final double selfRewardAmount;
  final double referrerRewardAmount;

  factory DepositRequestResult.fromJson(Map<String, dynamic> json) {
    return DepositRequestResult(
      id: (json['id'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      amount: _parseNum(json['amount']),
      selfRewardAmount: _parseNum(json['self_reward_amount']),
      referrerRewardAmount: _parseNum(json['referrer_reward_amount']),
    );
  }
}

class WithdrawalRequestResult {
  const WithdrawalRequestResult({
    required this.id,
    required this.status,
    required this.amount,
    required this.feeRatePercent,
    required this.feeAmount,
    required this.netAmount,
  });

  final String id;
  final String status;
  final double amount;
  final double feeRatePercent;
  final double feeAmount;
  final double netAmount;

  factory WithdrawalRequestResult.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestResult(
      id: (json['id'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      amount: _parseNum(json['amount']),
      feeRatePercent: _parseNum(json['fee_rate_percent']),
      feeAmount: _parseNum(json['fee_amount']),
      netAmount: _parseNum(json['net_amount']),
    );
  }
}

class DepositHistoryRecord {
  const DepositHistoryRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionType,
    required this.selfRewardAmount,
    required this.referrerRewardAmount,
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
  final String transactionType;
  final double selfRewardAmount;
  final double referrerRewardAmount;
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
      userId: _parseInt(json['user_id']),
      amount: _parseNum(json['amount']),
      transactionType: (json['transaction_type'] as String? ?? 'deposit')
          .trim()
          .toLowerCase(),
      selfRewardAmount: _parseNum(json['self_reward_amount']),
      referrerRewardAmount: _parseNum(json['referrer_reward_amount']),
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
    required this.transactionType,
    required this.capitalAmount,
    required this.signalProfitAmount,
    required this.rewardAmount,
    required this.feeRatePercent,
    required this.feeAmount,
    required this.netAmount,
    required this.status,
    required this.walletAddress,
    required this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final double amount;
  final String transactionType;
  final double capitalAmount;
  final double signalProfitAmount;
  final double rewardAmount;
  final double feeRatePercent;
  final double feeAmount;
  final double netAmount;
  final String status;
  final String? walletAddress;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory WithdrawalHistoryRecord.fromJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['updated_at'];
    return WithdrawalHistoryRecord(
      id: (json['id'] as String? ?? '').trim(),
      userId: _parseInt(json['user_id']),
      amount: _parseNum(json['amount']),
      transactionType: (json['transaction_type'] as String? ?? 'withdrawal')
          .trim()
          .toLowerCase(),
      capitalAmount: _parseNum(json['capital_amount']),
      signalProfitAmount: _parseNum(json['signal_profit_amount']),
      rewardAmount: _parseNum(json['reward_amount']),
      feeRatePercent: _parseNum(json['fee_rate_percent']),
      feeAmount: _parseNum(json['fee_amount']),
      netAmount: _parseNum(json['net_amount']),
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      walletAddress: (json['wallet_address'] as String?)?.trim(),
      adminNote: (json['admin_note'] as String?)?.trim(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: updatedAtRaw == null ? null : _parseDate(updatedAtRaw),
    );
  }
}

class WalletTransactionRecord {
  const WalletTransactionRecord({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String status;
  final double amount;
  final String? description;
  final DateTime createdAt;

  factory WalletTransactionRecord.fromJson(Map<String, dynamic> json) {
    return WalletTransactionRecord(
      id: _parseInt(json['id']),
      type: (json['type'] as String? ?? '').trim().toLowerCase(),
      status: (json['status'] as String? ?? 'completed').trim().toLowerCase(),
      amount: _parseNum(json['amount']),
      description: (json['description'] as String?)?.trim(),
      createdAt: _parseDate(json['created_at']),
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

  Future<List<WalletTransactionRecord>> getTransactions({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/wallet/transactions',
        queryParameters: <String, dynamic>{'skip': skip, 'limit': limit},
      );

      final items = response.data ?? const <dynamic>[];
      return items
          .map(
            (item) => WalletTransactionRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
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
    required String transactionRef,
  }) async {
    final proofBytes = await paymentProof.readAsBytes();
    final payload = FormData.fromMap({
      'amount': amount,
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
