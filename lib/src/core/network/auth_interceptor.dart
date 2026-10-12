import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/core/security/token_storage.dart';

/// QueuedInterceptor handling tenant key injection and atomic token refresh with guest fallback.
///
/// Because this is a [QueuedInterceptor], `onError` calls run one at a time,
/// so a burst of `401`s triggers a single refresh. The backend revokes a
/// refresh token the moment it is used, so two refreshes with the same token
/// would end the member's session (ADR 0010).
///
/// Token calls (refresh, guest token) and the replay of the failed request go
/// through [_tokenDio], a plain client with no interceptors. Sending them
/// through the intercepted client instead would deadlock the moment one of
/// them failed: its error would queue behind the very `onError` call that is
/// waiting for it.
class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final AppConfig appConfig;
  final Dio _tokenDio;
  final _sessionExpired = StreamController<void>.broadcast();

  /// Requests whose `401` means bad credentials, not an expired token.
  static const _noRenewalPaths = {
    ApiEndpoints.login,
    ApiEndpoints.memberRegister,
    ApiEndpoints.refreshToken,
    ApiEndpoints.guestToken,
    ApiEndpoints.logout,
  };

  AuthInterceptor({
    required this.tokenStorage,
    required this.appConfig,
    @visibleForTesting Dio? tokenDio,
  }) : _tokenDio = tokenDio ??
            Dio(
              BaseOptions(
                baseUrl: appConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'X-Tenant-Key': appConfig.tenantKey,
                },
              ),
            );

  /// Fires when the backend rejects the member's refresh token: the session
  /// is over and the app has fallen back to the guest token.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Injects X-Tenant-Key header across all requests
    options.headers['X-Tenant-Key'] = appConfig.tenantKey;

    final token = await _currentToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _noRenewalPaths.contains(options.path)) {
      return handler.next(err);
    }

    final token = await _renewedToken(sentToken: _bearerOf(options));
    if (token == null) {
      return handler.next(err);
    }

    try {
      return handler.resolve(await _replay(options, token));
    } on DioException catch (replayError) {
      // The replay's own failure (a 403, a 404, …) is the real answer now.
      return handler.next(replayError);
    }
  }

  /// The member's access token, or the guest token when nobody is signed in.
  Future<String?> _currentToken() async {
    final userToken = await tokenStorage.getAccessToken();
    if (userToken != null && userToken.isNotEmpty) return userToken;
    final guestToken = await tokenStorage.getGuestToken();
    if (guestToken != null && guestToken.isNotEmpty) return guestToken;
    return null;
  }

  /// A token to retry with after a `401` on a request sent with [sentToken],
  /// or null when there is none and the `401` stands.
  Future<String?> _renewedToken({required String? sentToken}) async {
    // An earlier queued `onError` already renewed the token while this request
    // was in flight: retry with that one rather than spending another refresh.
    final current = await _currentToken();
    if (current != null && current != sentToken) return current;

    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        return await _refreshSession(refreshToken);
      } on DioException catch (e) {
        // Offline, timed out or a server error: the session may still be
        // good, so keep it and let the next request try again.
        if (e.response?.statusCode != 401) return null;
      } catch (_) {
        // A malformed response; same as above.
        return null;
      }
      // The backend rejected the refresh token: revoked, expired, or the
      // member was deactivated. Carry on as a guest.
      await tokenStorage.clearUserSession();
      _sessionExpired.add(null);
    }

    return _renewGuestToken();
  }

  /// Trades [refreshToken] for a new token pair and stores it.
  Future<String> _refreshSession(String refreshToken) async {
    final response = await _tokenDio.post<Map<String, dynamic>>(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    final data = response.data!;
    final accessToken = data['access_token'] as String;
    await tokenStorage.saveUserTokens(
      accessToken: accessToken,
      refreshToken: data['refresh_token'] as String,
    );
    return accessToken;
  }

  /// Exchanges the app's client credentials for a fresh guest token.
  Future<String?> _renewGuestToken() async {
    if (!appConfig.hasClientCredentials) return null;
    try {
      final response = await _tokenDio.post<Map<String, dynamic>>(
        ApiEndpoints.guestToken,
        data: {
          'client_id': appConfig.clientId,
          'client_secret': appConfig.clientSecret,
          // Required for a platform client; a church's own client may name only its church.
          'tenant_key': appConfig.tenantKey,
        },
      );
      final guestToken = response.data!['access_token'] as String;
      await tokenStorage.saveGuestToken(guestToken);
      return guestToken;
    } catch (_) {
      return null;
    }
  }

  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  /// Sends the failed request again with [token], bypassing this interceptor.
  Future<Response<dynamic>> _replay(RequestOptions options, String token) {
    options.headers['Authorization'] = 'Bearer $token';
    // A multipart body is consumed by the first send.
    final data = options.data;
    if (data is FormData) options.data = data.clone();
    return _tokenDio.fetch<dynamic>(options);
  }
}
