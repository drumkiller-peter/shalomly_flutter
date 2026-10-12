import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/core/config/app_config.dart';
import 'package:shalomly_app/src/core/network/api_endpoints.dart';
import 'package:shalomly_app/src/core/network/auth_interceptor.dart';
import 'package:shalomly_app/src/core/security/token_storage.dart';

const _config = AppConfig(
  tenantKey: 'grace',
  apiBaseUrl: 'http://api.test',
  isBaked: true,
  clientId: 'grace_client',
  clientSecret: 'secret',
);

/// A fake backend: answers each request from [handle], recording what it saw.
class _FakeBackend implements HttpClientAdapter {
  _FakeBackend(this.handle);

  final Future<(int, Object?)> Function(RequestOptions) handle;
  final requests = <RequestOptions>[];

  int callsTo(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = await handle(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String? _bearer(RequestOptions r) =>
    (r.headers['Authorization'] as String?)?.substring('Bearer '.length);

void main() {
  late TokenStorage storage;
  late AuthInterceptor interceptor;
  late Dio dio;

  Dio buildClients(_FakeBackend backend) {
    final tokenDio = Dio(BaseOptions(baseUrl: _config.apiBaseUrl))
      ..httpClientAdapter = backend;
    interceptor = AuthInterceptor(
      tokenStorage: storage,
      appConfig: _config,
      tokenDio: tokenDio,
    );
    return Dio(BaseOptions(baseUrl: _config.apiBaseUrl))
      ..httpClientAdapter = backend
      ..interceptors.add(interceptor);
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'expired-access',
      'refresh_token': 'refresh-1',
      'guest_token': 'guest-1',
    });
    storage = const TokenStorage();
  });

  /// Accepts only `fresh-access`; refresh answers with [refreshAnswer].
  _FakeBackend backendWith({
    required Future<(int, Object?)> Function() refreshAnswer,
  }) {
    return _FakeBackend((r) async {
      switch (r.path) {
        case ApiEndpoints.refreshToken:
          return refreshAnswer();
        case ApiEndpoints.guestToken:
          return (200, {'access_token': 'guest-2'});
      }
      final token = _bearer(r);
      if (token == 'fresh-access' || token == 'guest-2') {
        return (200, {'token': token});
      }
      return (401, {'detail': 'Invalid or expired token'});
    });
  }

  Future<(int, Object?)> rotated() async => (
    200,
    {'access_token': 'fresh-access', 'refresh_token': 'refresh-2'},
  );

  test('a 401 refreshes the session and replays the request', () async {
    final backend = backendWith(refreshAnswer: rotated);
    dio = buildClients(backend);

    final response = await dio.get<Map<String, dynamic>>('/events');

    expect(response.data, {'token': 'fresh-access'});
    expect(await storage.getAccessToken(), 'fresh-access');
    expect(await storage.getRefreshToken(), 'refresh-2');
  });

  test('a burst of 401s spends the refresh token only once', () async {
    final backend = backendWith(
      refreshAnswer: () async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return rotated();
      },
    );
    dio = buildClients(backend);

    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/events'),
      dio.get<Map<String, dynamic>>('/hymns'),
      dio.get<Map<String, dynamic>>('/sermons'),
    ]);

    expect(responses.map((r) => r.data!['token']), everyElement('fresh-access'));
    expect(backend.callsTo(ApiEndpoints.refreshToken), 1);
  });

  test('a rejected refresh token ends the session and falls back to the '
      'guest token', () async {
    final backend = backendWith(
      refreshAnswer: () async => (401, {'detail': 'revoked'}),
    );
    dio = buildClients(backend);
    var expired = 0;
    interceptor.sessionExpired.listen((_) => expired++);

    final response = await dio.get<Map<String, dynamic>>('/events');
    await Future<void>.delayed(Duration.zero);

    expect(response.data, {'token': 'guest-2'});
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getGuestToken(), 'guest-2');
    expect(expired, 1);
  });

  test('a refresh that never reaches the backend keeps the session', () async {
    final backend = backendWith(
      refreshAnswer: () async => throw const SocketLikeError(),
    );
    dio = buildClients(backend);
    var expired = 0;
    interceptor.sessionExpired.listen((_) => expired++);

    await expectLater(
      dio.get<void>('/events'),
      throwsA(
        isA<DioException>().having((e) => e.response?.statusCode, 'status', 401),
      ),
    );
    expect(await storage.getRefreshToken(), 'refresh-1');
    expect(expired, 0);
  });

  test('a replay that fails for another reason keeps the new session',
      () async {
    final backend = _FakeBackend((r) async {
      if (r.path == ApiEndpoints.refreshToken) return rotated();
      if (_bearer(r) == 'fresh-access') return (403, {'detail': 'Forbidden'});
      return (401, {'detail': 'expired'});
    });
    dio = buildClients(backend);

    await expectLater(
      dio.get<void>('/prayers/private'),
      throwsA(
        isA<DioException>().having((e) => e.response?.statusCode, 'status', 403),
      ),
    );
    expect(await storage.getRefreshToken(), 'refresh-2');
  });

  test('a wrong password on sign-in is not retried', () async {
    final backend = backendWith(refreshAnswer: rotated);
    dio = buildClients(backend);

    await expectLater(
      dio.post<void>(ApiEndpoints.login, data: {'identifier': 'a'}),
      throwsA(isA<DioException>()),
    );
    expect(backend.callsTo(ApiEndpoints.refreshToken), 0);
    expect(backend.callsTo(ApiEndpoints.login), 1);
  });
}

/// Stands in for a dropped connection.
class SocketLikeError implements Exception {
  const SocketLikeError();
}
