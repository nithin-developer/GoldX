import 'package:dio/dio.dart';
import 'package:signalpro/app/models/app_notification.dart';
import 'package:signalpro/app/models/home_dashboard.dart';
import 'package:signalpro/app/models/referral_models.dart';
import 'package:signalpro/app/models/signal_feed_item.dart';
import 'package:signalpro/app/models/signal_history_item.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/services/api_exception.dart';

class AppDataApi {
  AppDataApi({required Dio dio})
    : _dio = dio,
      _cacheNamespace = _activeCacheNamespace;

  final Dio _dio;
  final String _cacheNamespace;

  static int _sessionRevision = 0;
  static String _activeCacheNamespace = 'session:0';
  static final Set<String> _retiredCacheNamespaces = <String>{};
  static final Map<String, _SessionCacheBucket> _cacheBucketsByNamespace = {
    _activeCacheNamespace: _SessionCacheBucket(),
  };
  static final _SessionCacheBucket _discardedCacheBucket =
      _SessionCacheBucket();

  static int get sessionRevision => _sessionRevision;

  static int startNewSessionCache() {
    final previousNamespace = _activeCacheNamespace;
    _retiredCacheNamespaces.add(previousNamespace);
    _cacheBucketsByNamespace.remove(previousNamespace);

    _sessionRevision += 1;
    _activeCacheNamespace = 'session:$_sessionRevision';
    _cacheBucketsByNamespace[_activeCacheNamespace] = _SessionCacheBucket();
    _discardedCacheBucket.clear();
    return _sessionRevision;
  }

  static void clearAllCaches({bool includeRetiredNamespaces = false}) {
    if (includeRetiredNamespaces) {
      _cacheBucketsByNamespace.clear();
      _retiredCacheNamespaces.clear();
      _discardedCacheBucket.clear();
      _cacheBucketsByNamespace[_activeCacheNamespace] = _SessionCacheBucket();
      return;
    }

    _cacheBucketsByNamespace[_activeCacheNamespace]?.clear();
  }

  _SessionCacheBucket get _cache {
    final namespace = _cacheNamespace;
    if (namespace != _activeCacheNamespace &&
        _retiredCacheNamespaces.contains(namespace)) {
      return _discardedCacheBucket;
    }

    return _cacheBucketsByNamespace.putIfAbsent(
      namespace,
      _SessionCacheBucket.new,
    );
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
    final cached = _cache.signalCache[key];
    if (cached == null) {
      return null;
    }
    return List<SignalFeedItem>.from(cached);
  }

  List<SignalHistoryItem>? getCachedSignalHistory() {
    final cached = _cache.signalHistoryCache;
    if (cached == null) {
      return null;
    }

    return List<SignalHistoryItem>.from(cached);
  }

  String _referralsCacheKey({required int skip, required int limit}) {
    return '$skip:$limit';
  }

  ReferralStats? getCachedReferralStats() {
    return _cache.referralStatsCache;
  }

  List<ReferralItem>? getCachedReferrals({int skip = 0, int limit = 20}) {
    final key = _referralsCacheKey(skip: skip, limit: limit);
    final cached = _cache.referralsCache[key];
    if (cached == null) {
      return null;
    }
    return List<ReferralItem>.from(cached);
  }

  UserProfile? getCachedProfile() {
    return _cache.profileCache;
  }

  List<AppNotification>? getCachedNotifications() {
    final cached = _cache.notificationsCache;
    if (cached == null) {
      return null;
    }

    return List<AppNotification>.from(cached);
  }

  int? getCachedUnreadNotificationsCount() {
    return _cache.unreadNotificationsCache;
  }

  HomeDashboardData? getCachedHomeDashboard() {
    return _cache.homeDashboardCache;
  }

  Future<List<AppNotification>> getNotifications({
    bool forceRefresh = false,
    int pageSize = 100,
    int maxItems = 1000,
  }) async {
    final cache = _cache;
    if (!forceRefresh && cache.notificationsCache != null) {
      return List<AppNotification>.from(cache.notificationsCache!);
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

      cache.notificationsCache = mapped;
      cache.unreadNotificationsCache = mapped
          .where((item) => item.isUnread)
          .length;
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

      final cache = _cache;
      if (cache.notificationsCache != null) {
        if (markAll) {
          cache.notificationsCache = cache.notificationsCache!
              .map((item) => item.copyWith(isRead: true))
              .toList();
        } else {
          final ids = notificationIds.toSet();
          cache.notificationsCache = cache.notificationsCache!
              .map(
                (item) =>
                    ids.contains(item.id) ? item.copyWith(isRead: true) : item,
              )
              .toList();
        }

        cache.unreadNotificationsCache = cache.notificationsCache!
            .where((item) => item.isUnread)
            .length;
      } else if (markAll) {
        cache.unreadNotificationsCache = 0;
      } else if (cache.unreadNotificationsCache != null) {
        final remaining =
            cache.unreadNotificationsCache! - notificationIds.length;
        cache.unreadNotificationsCache = remaining < 0 ? 0 : remaining;
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
    final cache = _cache;
    if (!forceRefresh && canUseCache) {
      final cached = cache.signalCache[key];
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
        cache.signalCache[key] = mapped;
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
    final cache = _cache;
    if (!forceRefresh && canUseCache && cache.signalHistoryCache != null) {
      return List<SignalHistoryItem>.from(cache.signalHistoryCache!);
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
        cache.signalHistoryCache = mapped;
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

      final cache = _cache;
      cache.signalCache.clear();
      cache.signalHistoryCache = null;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<ReferralStats> getReferralStats({bool forceRefresh = false}) async {
    final cache = _cache;
    if (!forceRefresh && cache.referralStatsCache != null) {
      return cache.referralStatsCache!;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/referrals/stats',
        queryParameters: {
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final stats = ReferralStats.fromJson(response.data ?? const {});
      cache.referralStatsCache = stats;
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
    final cache = _cache;
    if (!forceRefresh) {
      final cached = cache.referralsCache[key];
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

      cache.referralsCache[key] = referrals;
      return List<ReferralItem>.from(referrals);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<UserProfile> getProfile({bool forceRefresh = false}) async {
    final cache = _cache;
    if (!forceRefresh && cache.profileCache != null) {
      return cache.profileCache!;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/profile',
        queryParameters: {
          if (forceRefresh) '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final profile = UserProfile.fromJson(response.data ?? const {});
      cache.profileCache = profile;
      return profile;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<int> getUnreadNotificationsCount({bool forceRefresh = false}) async {
    final cache = _cache;
    if (!forceRefresh) {
      if (cache.unreadNotificationsCache != null) {
        return cache.unreadNotificationsCache!;
      }

      if (cache.notificationsCache != null) {
        cache.unreadNotificationsCache = cache.notificationsCache!
            .where((item) => item.isUnread)
            .length;
        return cache.unreadNotificationsCache!;
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
      cache.unreadNotificationsCache = count;
      return count;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<HomeDashboardData> getHomeDashboard({
    bool forceRefresh = false,
    int activityLimit = 5,
  }) async {
    final cache = _cache;
    if (!forceRefresh && cache.homeDashboardCache != null) {
      return cache.homeDashboardCache!;
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
      cache.homeDashboardCache = data;
      return data;
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

class _SessionCacheBucket {
  final Map<String, List<SignalFeedItem>> signalCache =
      <String, List<SignalFeedItem>>{};
  List<SignalHistoryItem>? signalHistoryCache;
  ReferralStats? referralStatsCache;
  final Map<String, List<ReferralItem>> referralsCache =
      <String, List<ReferralItem>>{};
  List<AppNotification>? notificationsCache;
  UserProfile? profileCache;
  int? unreadNotificationsCache;
  HomeDashboardData? homeDashboardCache;

  void clear() {
    signalCache.clear();
    signalHistoryCache = null;
    referralStatsCache = null;
    referralsCache.clear();
    notificationsCache = null;
    profileCache = null;
    unreadNotificationsCache = null;
    homeDashboardCache = null;
  }
}
