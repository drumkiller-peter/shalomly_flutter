import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/core/security/token_storage.dart';
import 'package:shalomly_app/src/features/auth/data/auth_repository.dart';

const _member = {
  'id': 1,
  'tenant_id': 1,
  'full_name': 'Ruth Member',
  'email': 'ruth@church.org',
  'role': 'member',
  'language_preference': 'en',
  'privacy_settings': {
    'show_email': false,
    'show_phone': false,
    'show_in_directory': true,
    'give_anonymously': false,
  },
  'is_active': true,
  'created_at': '2026-01-01T00:00:00Z',
};

/// A backend that answers `/auth/me` from a script: each entry is a status
/// code, or `null` for a request that times out (a sleeping server).
class _ScriptedBackend implements HttpClientAdapter {
  _ScriptedBackend(this.script);

  final List<int?> script;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final next = script[calls < script.length ? calls : script.length - 1];
    calls++;
    if (next == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(next == 200 ? _member : {'detail': 'no'}),
      next,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late TokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access-1',
      'refresh_token': 'refresh-1',
    });
    storage = const TokenStorage();
  });

  AuthRepository repositoryFor(_ScriptedBackend backend) {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = backend;
    return AuthRepository(
      dio: dio,
      tokenStorage: storage,
      sessionExpired: const Stream.empty(),
      retryDelay: Duration.zero,
    );
  }

  test('a server that is still waking up is waited for, not taken as a sign-out', () async {
    final backend = _ScriptedBackend([null, null, 200]);

    final user = await repositoryFor(backend).checkAuth();

    expect(user?.fullName, 'Ruth Member');
    expect(backend.calls, 3);
  });

  test('a server error while it boots is retried too', () async {
    final backend = _ScriptedBackend([503, 200]);

    final user = await repositoryFor(backend).checkAuth();

    expect(user, isNotNull);
    expect(backend.calls, 2);
  });

  test('a rejected token is an answer, not a reason to retry', () async {
    final backend = _ScriptedBackend([401]);

    final user = await repositoryFor(backend).checkAuth();

    expect(user, isNull);
    expect(backend.calls, 1);
  });

  test('a server that stays unreachable leaves the member\'s tokens in place', () async {
    final backend = _ScriptedBackend([null]);

    final user = await repositoryFor(backend).checkAuth();

    expect(user, isNull);
    expect(backend.calls, 3);
    expect(await storage.getRefreshToken(), 'refresh-1');
    expect(await storage.getAccessToken(), 'access-1');
  });
}
