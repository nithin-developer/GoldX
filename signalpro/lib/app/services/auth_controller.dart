import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:signalpro/app/models/auth_tokens.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/services/api_client.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_api.dart';
import 'package:signalpro/app/services/token_storage.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthController extends ChangeNotifier implements AuthSessionDelegate {
  AuthController({AuthApi? authApi, TokenStorage? tokenStorage})
      : _authApi = authApi ?? AuthApi(),
        _tokenStorage = tokenStorage ?? TokenStorage() {
    apiClient = ApiClient(authSessionDelegate: this);
  }

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.checking;
  AuthStatus get status => _status;

  AuthTokens? _tokens;
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  late final ApiClient apiClient;
  Future<bool>? _refreshFuture;

  @override
  String? get accessToken => _tokens?.accessToken;

  Future<void> initialize() async {
    _status = AuthStatus.checking;
    notifyListeners();

    final storedTokens = await _tokenStorage.readTokens();

    if (storedTokens == null) {
      _tokens = null;
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _tokens = storedTokens;
    final restored = await _syncSessionWithServer();

    _status = restored ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<String?> login({required String email, required String password}) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final tokens = await _authApi.login(email: email, password: password);
      _tokens = tokens;
      await _tokenStorage.saveTokens(tokens);
      _currentUser = await _fetchMeWithClient();
      _status = AuthStatus.authenticated;
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await _authApi.validateInviteCode(inviteCode: inviteCode);

      final tokens = await _authApi.register(
        fullName: fullName,
        email: email,
        password: password,
        inviteCode: inviteCode,
      );
      _tokens = tokens;
      await _tokenStorage.saveTokens(tokens);
      _currentUser = await _fetchMeWithClient();
      _status = AuthStatus.authenticated;
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _tokens = null;
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    await _tokenStorage.clear();
    notifyListeners();
  }

  Future<void> reloadUser() async {
    if (_tokens == null) {
      return;
    }

    final success = await _syncSessionWithServer();
    if (!success) {
      await logout();
    } else {
      notifyListeners();
    }
  }

  Future<bool> _syncSessionWithServer() async {
    if (_tokens == null) {
      return false;
    }

    try {
      _currentUser = await _fetchMeWithClient();
      return true;
    } on ApiException {
      final refreshed = await refreshAccessToken();
      if (!refreshed || _tokens == null) {
        _currentUser = null;
        return false;
      }

      try {
        _currentUser = await _fetchMeWithClient();
        return true;
      } on ApiException {
        _currentUser = null;
        return false;
      }
    }
  }

  @override
  Future<bool> refreshAccessToken() async {
    if (_tokens == null) {
      return false;
    }

    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _performRefresh();
    final result = await _refreshFuture!;
    _refreshFuture = null;
    return result;
  }

  Future<bool> _performRefresh() async {
    final refreshToken = _tokens?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final updatedTokens = await _authApi.refreshToken(refreshToken: refreshToken);
      _tokens = updatedTokens;
      await _tokenStorage.saveTokens(updatedTokens);
      return true;
    } on ApiException {
      _tokens = null;
      _currentUser = null;
      await _tokenStorage.clear();
      return false;
    }
  }

  @override
  Future<void> handleSessionExpired() async {
    await logout();
  }

  Future<UserProfile> _fetchMeWithClient() async {
    try {
      final response = await apiClient.dio.get<Map<String, dynamic>>('/auth/me');
      return UserProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
