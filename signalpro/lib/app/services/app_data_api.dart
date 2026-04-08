import 'package:dio/dio.dart';
import 'package:signalpro/app/models/app_notification.dart';
import 'package:signalpro/app/models/home_dashboard.dart';
import 'package:signalpro/app/models/referral_models.dart';
import 'package:signalpro/app/models/signal_feed_item.dart';
import 'package:signalpro/app/models/signal_history_item.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/services/api_exception.dart';

class AppDataApi {
  const AppDataApi({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static final Map<String, List<SignalFeedItem>> _signalCache = {};
  static List<SignalHistoryItem>? _signalHistoryCache;
  static ReferralStats? _referralStatsCache;
  static final Map<String, List<ReferralItem>> _referralsCache = {};
  static List<AppNotification>? _notificationsCache;
  static UserProfile? _profileCache;
  static int? _unreadNotificationsCache;
  static HomeDashboardData? _homeDashboardCache;

  static void clearAllCaches() {
    _signalCache.clear();
    _signalHistoryCache = null;
    _referralStatsCache = null;
    _referralsCache.clear();
    _notificationsCache = null;
    _profileCache = null;
    _unreadNotificationsCache = null;
    _homeDashboardCache = null;
  }

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

  List<SignalHistoryItem>? getCachedSignalHistory() {
    final cached = _signalHistoryCache;
    if (cached == null) {
      return null;
    }

    return List<SignalHistoryItem>.from(cached);
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

  List<AppNotification>? getCachedNotifications() {
    final cached = _notificationsCache;
    if (cached == null) {
      return null;
    }

    return List<AppNotification>.from(cached);
  }

  int? getCachedUnreadNotificationsCount() {
    return _unreadNotificationsCache;
  }

  HomeDashboardData? getCachedHomeDashboard() {
    return _homeDashboardCache;
  }

  Future<List<AppNotification>> getNotifications({
    bool forceRefresh = false,
    int pageSize = 100,
    int maxItems = 1000,
  }) async {
    if (!forceRefresh && _notificationsCache != null) {
      return List<AppNotification>.from(_notificationsCache!);
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      var skip = 0;
      final mapped = <AppNotification>[];

      while (true) {
        final response = await _dio.get<List<dynamic>>(
          '/notifications',
          queryParameters: {
            'skip': skip,
            'limit': pageSize,
            if (forceRefresh) '_ts': timestamp,
          },
        );

        final chunk = (response.data ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();

        mapped.addAll(chunk);
        if (chunk.length < pageSize || mapped.length >= maxItems) {
          break;
        }

        skip += pageSize;
      }

      _notificationsCache = mapped;
      _unreadNotificationsCache = mapped.where((item) => item.isUnread).length;
      return List<AppNotification>.from(mapped);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> markNotificationsRead({
    bool markAll = false,
    List<int> notificationIds = const [],
  }) async {
    if (!markAll && notificationIds.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'mark_all': markAll,
      if (notificationIds.isNotEmpty) 'notification_ids': notificationIds,
    };

    try {
      await _dio.put<void>('/notifications/read', data: payload);

      if (_notificationsCache != null) {
        if (markAll) {
          _notificationsCache = _notificationsCache!
              .map((item) => item.copyWith(isRead: true))
              .toList();
        } else {
          final ids = notificationIds.toSet();
          _notificationsCache = _notificationsCache!
              .map(
                (item) =>
                    ids.contains(item.id) ? item.copyWith(isRead: true) : item,
              )
              .toList();
        }

        _unreadNotificationsCache = _notificationsCache!
            .where((item) => item.isUnread)
            .length;
      } else if (markAll) {
        _unreadNotificationsCache = 0;
      } else if (_unreadNotificationsCache != null) {
        final remaining = _unreadNotificationsCache! - notificationIds.length;
        _unreadNotificationsCache = remaining < 0 ? 0 : remaining;
      }
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<SignalFeedItem>> getSignals({
    String? status,
    bool forceRefresh = false,
    int skip = 0,
    int limit = 100,
    bool includeAllStatuses = false,
  }) async {
    final key = _signalsCacheKey(status);
    final canUseCache = !includeAllStatuses && skip == 0 && limit == 100;
    if (!forceRefresh && canUseCache) {
      final cached = _signalCache[key];
      if (cached != null) {
        return List<SignalFeedItem>.from(cached);
      }
    }

    try {
      final normalizedStatus = status?.trim();
      final hasStatusFilter =
          normalizedStatus != null && normalizedStatus.isNotEmpty;
      final useAllEndpoint =
          includeAllStatuses || hasStatusFilter || skip > 0 || limit != 100;
      final response = await _dio.get<List<dynamic>>(
        useAllEndpoint ? '/signals/all' : '/signals',
        queryParameters: {
          if (useAllEndpoint && hasStatusFilter) 'status': normalizedStatus,
          if (useAllEndpoint) 'skip': skip,
          'limit': limit,
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final data = response.data ?? const [];

      final mapped = data
          .whereType<Map<String, dynamic>>()
          .map(SignalFeedItem.fromJson)
          .toList();

      if (canUseCache) {
        _signalCache[key] = mapped;
      }

      return List<SignalFeedItem>.from(mapped);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<SignalHistoryItem>> getSignalHistory({
    bool forceRefresh = false,
    int skip = 0,
    int limit = 100,
  }) async {
    final canUseCache = skip == 0 && limit == 100;
    if (!forceRefresh && canUseCache && _signalHistoryCache != null) {
      return List<SignalHistoryItem>.from(_signalHistoryCache!);
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        '/signals/history',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final data = response.data ?? const [];
      final mapped = data
          .whereType<Map<String, dynamic>>()
          .map(SignalHistoryItem.fromJson)
          .toList();

      if (canUseCache) {
        _signalHistoryCache = mapped;
      }

      return List<SignalHistoryItem>.from(mapped);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> activateSignal({required String signalCode}) async {
    final normalizedCode = signalCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw ApiException('Please enter activation code');
    }

    try {
      await _dio.post<void>(
        '/signals/activate',
        data: {'signal_code': normalizedCode},
      );

      _signalCache.clear();
      _signalHistoryCache = null;
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
    if (!forceRefresh) {
      if (_unreadNotificationsCache != null) {
        return _unreadNotificationsCache!;
      }

      if (_notificationsCache != null) {
        _unreadNotificationsCache = _notificationsCache!
            .where((item) => item.isUnread)
            .length;
        return _unreadNotificationsCache!;
      }
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

  Future<HomeDashboardData> getHomeDashboard({
    bool forceRefresh = false,
    int activityLimit = 5,
  }) async {
    if (!forceRefresh && _homeDashboardCache != null) {
      return _homeDashboardCache!;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/dashboard/home',
        queryParameters: {
          'activity_limit': activityLimit,
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final data = HomeDashboardData.fromJson(response.data ?? const {});
      _homeDashboardCache = data;
      return data;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
