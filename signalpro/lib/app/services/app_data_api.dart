import 'package:dio/dio.dart';
import 'package:signalpro/app/models/referral_models.dart';
import 'package:signalpro/app/models/signal_feed_item.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/services/api_exception.dart';

class AppDataApi {
  const AppDataApi({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static final Map<String, List<SignalFeedItem>> _signalCache = {};
  static ReferralStats? _referralStatsCache;
  static final Map<String, List<ReferralItem>> _referralsCache = {};
  static UserProfile? _profileCache;
  static int? _unreadNotificationsCache;

  String _signalsCacheKey(String? status) {
    final normalized = status?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'all';
    }
    return normalized.toLowerCase();
  }

  List<SignalFeedItem>? getCachedSignals({String? status}) {
    final key = _signalsCacheKey(status);
    final cached = _signalCache[key];
    if (cached == null) {
      return null;
    }
    return List<SignalFeedItem>.from(cached);
  }

  String _referralsCacheKey({required int skip, required int limit}) {
    return '$skip:$limit';
  }

  ReferralStats? getCachedReferralStats() {
    return _referralStatsCache;
  }

  List<ReferralItem>? getCachedReferrals({int skip = 0, int limit = 20}) {
    final key = _referralsCacheKey(skip: skip, limit: limit);
    final cached = _referralsCache[key];
    if (cached == null) {
      return null;
    }
    return List<ReferralItem>.from(cached);
  }

  UserProfile? getCachedProfile() {
    return _profileCache;
  }

  int? getCachedUnreadNotificationsCount() {
    return _unreadNotificationsCache;
  }

  Future<List<SignalFeedItem>> getSignals({
    String? status,
    bool forceRefresh = false,
  }) async {
    final key = _signalsCacheKey(status);
    if (!forceRefresh) {
      final cached = _signalCache[key];
      if (cached != null) {
        return List<SignalFeedItem>.from(cached);
      }
    }

    Future<List<dynamic>> fetch(String path) async {
      final response = await _dio.get<List<dynamic>>(
        path,
        queryParameters: {
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
          'limit': 100,
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      return response.data ?? const [];
    }

    try {
      List<dynamic> data;
      try {
        data = await fetch('/signals/all');
      } on DioException catch (error) {
        if (error.response?.statusCode == 404) {
          data = await fetch('/signals');
        } else {
          rethrow;
        }
      }

      final mapped = data
          .whereType<Map<String, dynamic>>()
          .map(SignalFeedItem.fromJson)
          .toList();

      _signalCache[key] = mapped;
      return List<SignalFeedItem>.from(mapped);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<ReferralStats> getReferralStats({bool forceRefresh = false}) async {
    if (!forceRefresh && _referralStatsCache != null) {
      return _referralStatsCache!;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/referrals/stats',
        queryParameters: {
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final stats = ReferralStats.fromJson(response.data ?? const {});
      _referralStatsCache = stats;
      return stats;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<ReferralItem>> getReferrals({
    int skip = 0,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final key = _referralsCacheKey(skip: skip, limit: limit);
    if (!forceRefresh) {
      final cached = _referralsCache[key];
      if (cached != null) {
        return List<ReferralItem>.from(cached);
      }
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        '/referrals',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final data = response.data ?? const [];

      final referrals = data
          .whereType<Map<String, dynamic>>()
          .map(ReferralItem.fromJson)
          .toList();

      _referralsCache[key] = referrals;
      return List<ReferralItem>.from(referrals);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UserProfile> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _profileCache != null) {
      return _profileCache!;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/profile',
        queryParameters: {
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final profile = UserProfile.fromJson(response.data ?? const {});
      _profileCache = profile;
      return profile;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<int> getUnreadNotificationsCount({bool forceRefresh = false}) async {
    if (!forceRefresh && _unreadNotificationsCache != null) {
      return _unreadNotificationsCache!;
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        '/notifications',
        queryParameters: {
          'unread_only': true,
          'limit': 100,
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final count = (response.data ?? const []).length;
      _unreadNotificationsCache = count;
      return count;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
