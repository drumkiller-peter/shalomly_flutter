import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shalomly_app/src/core/security/token_storage.dart';
import 'package:shalomly_app/src/features/auth/data/auth_repository.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';
import 'package:shalomly_app/src/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  test('an expired session signs the member out', () async {
    final sessionExpired = StreamController<void>.broadcast();
    final bloc = AuthBloc(
      authRepository: AuthRepository(
        dio: Dio(),
        tokenStorage: const TokenStorage(),
        sessionExpired: sessionExpired.stream,
      ),
    );
    addTearDown(bloc.close);
    addTearDown(sessionExpired.close);
    bloc.emit(
      Authenticated(
        User(
          id: 1,
          tenantId: 1,
          fullName: 'Ruth Member',
          email: 'ruth@church.org',
          role: UserRole.member,
          languagePreference: 'en',
          privacySettings: const PrivacySettings(
            showEmail: false,
            showPhone: false,
            showInDirectory: true,
            giveAnonymously: false,
          ),
          isActive: true,
          createdAt: DateTime(2026),
        ),
      ),
    );

    sessionExpired.add(null);

    await expectLater(bloc.stream, emits(const UnauthenticatedGuest()));
  });
}
