import 'package:dio/dio.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/core/security/token_storage.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';

class AuthRepository {
  final Dio dio;
  final TokenStorage tokenStorage;

  /// Fires when the backend ends the member's session by rejecting its
  /// refresh token; see `AuthInterceptor.sessionExpired`.
  final Stream<void> sessionExpired;

  /// How long to wait between tries when the server isn't answering.
  final Duration retryDelay;

  AuthRepository({
    required this.dio,
    required this.tokenStorage,
    required this.sessionExpired,
    this.retryDelay = const Duration(seconds: 3),
  });

  /// Tries at launch to find out who is signed in, and how long to wait for
  /// each. A server that has been idle can take up to a minute to wake, which
  /// is longer than the client's usual 15 seconds.
  static const _checkAttempts = 3;
  static const _wakeUpTimeout = Duration(seconds: 45);

  /// The signed-in member, or null when nobody is, or the server refused the
  /// session. A server that doesn't answer (asleep, offline, or failing) is
  /// not a sign-out: it is waited for and tried again, and if it stays silent
  /// the stored tokens are kept, so the next launch can still sign in.
  Future<User?> checkAuth() async {
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    for (var attempt = 1; attempt <= _checkAttempts; attempt++) {
      try {
        final response = await dio.get<Map<String, dynamic>>(
          ApiEndpoints.me,
          options: Options(receiveTimeout: _wakeUpTimeout),
        );
        if (response.statusCode == 200 && response.data != null) {
          final user = User.fromJson(response.data!);
          // Only the role: the call may have refreshed the tokens on the way.
          await tokenStorage.saveUserRole(user.role.value);
          return user;
        }
        return null;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final serverSilent = status == null || status >= 500;
        if (!serverSilent) return null;
        if (attempt < _checkAttempts) await Future<void>.delayed(retryDelay);
      } catch (_) {
        // A reply the app can't read: no point asking again.
        return null;
      }
    }
    return null;
  }

  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'identifier': identifier, 'password': password},
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data!;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      await tokenStorage.saveUserTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Fetch user profile immediately after login
      final profileResponse = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.me,
      );
      final user = User.fromJson(profileResponse.data!);
      await tokenStorage.saveUserRole(user.role.value);

      return user;
    } else {
      throw Exception('Login failed');
    }
  }

  Future<User> registerMember({
    required String fullName,
    String? email,
    String? phone,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      ApiEndpoints.memberRegister,
      data: {
        'full_name': fullName,
        'email': ?email,
        'phone': ?phone,
        'password': password,
      },
    );

    if (response.statusCode == 201 && response.data != null) {
      final data = response.data!;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final tokens = data['tokens'] as Map<String, dynamic>;

      await tokenStorage.saveUserTokens(
        accessToken: tokens['access_token'] as String,
        refreshToken: tokens['refresh_token'] as String,
        userRole: user.role.value,
      );

      return user;
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await dio.post<void>(
          ApiEndpoints.logout,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {
      // Ignored: revoke locally even if remote call fails
    } finally {
      await tokenStorage.clearUserSession();
    }
  }
}
