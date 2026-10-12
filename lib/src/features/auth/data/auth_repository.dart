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

  AuthRepository({
    required this.dio,
    required this.tokenStorage,
    required this.sessionExpired,
  });

  Future<User?> checkAuth() async {
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.me,
      );
      if (response.statusCode == 200 && response.data != null) {
        final user = User.fromJson(response.data!);
        // Only the role: the call may have refreshed the tokens on the way.
        await tokenStorage.saveUserRole(user.role.value);
        return user;
      }
    } catch (_) {
      // Failed to validate token or offline
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
