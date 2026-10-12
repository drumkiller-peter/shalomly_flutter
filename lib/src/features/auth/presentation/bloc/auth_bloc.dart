import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/features/auth/data/auth_repository.dart';
import 'package:shalomly_app/src/features/auth/domain/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  late final StreamSubscription<void> _sessionExpiredSubscription;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    _sessionExpiredSubscription = authRepository.sessionExpired.listen(
      (_) => add(const AuthSessionExpired()),
    );
  }

  @override
  Future<void> close() async {
    await _sessionExpiredSubscription.cancel();
    return super.close();
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.checkAuth();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const UnauthenticatedGuest());
      }
    } catch (_) {
      emit(const UnauthenticatedGuest());
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.login(
        identifier: event.identifier,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(const UnauthenticatedGuest());
    }
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.registerMember(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      emit(const UnauthenticatedGuest());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await authRepository.logout();
    emit(const UnauthenticatedGuest());
  }

  /// The tokens are already cleared and the app is back on the guest token;
  /// this only brings the UI along.
  void _onSessionExpired(AuthSessionExpired event, Emitter<AuthState> emit) {
    emit(const UnauthenticatedGuest());
  }
}
