import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/barber.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_barber_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_state.dart';

/// Drives the whole app's authentication gate. [RootShell] listens to this
/// cubit to decide whether to show the login screen or the bottom-nav shell.
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentBarberUseCase _getCurrentBarberUseCase;
  final AuthRepository _authRepository;

  StreamSubscription<Barber?>? _authSubscription;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentBarberUseCase getCurrentBarberUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentBarberUseCase = getCurrentBarberUseCase,
        _authRepository = authRepository,
        super(const AuthState()) {
    _bootstrap();
  }

  void _bootstrap() {
    _authSubscription = _authRepository.watchAuthState().listen((barber) {
      if (barber != null) {
        emit(state.copyWith(status: AuthStatus.authenticated, barber: barber, clearError: true));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated, clearBarber: true));
      }
    });
  }

  Future<void> login({required String phoneNumber, required String password}) async {
    debugPrint('[AuthCubit] login() started for phoneNumber=$phoneNumber');
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final barber = await _loginUseCase(phoneNumber: phoneNumber, password: password);
      debugPrint('[AuthCubit] login() succeeded for uid=${barber.uid}');
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        barber: barber,
        submitting: false,
        clearError: true,
      ));
    } on AppException catch (e) {
      debugPrint('[AuthCubit] login() failed with AppException: ${e.message}');
      emit(state.copyWith(submitting: false, errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('[AuthCubit] login() failed with unexpected error: $e');
      debugPrint('$stackTrace');
      emit(state.copyWith(submitting: false, errorMessage: 'Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.'));
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
  }

  /// Optional eager restore, called once at app start so the splash/login
  /// decision doesn't have to wait for the first stream event on slow
  /// connections.
  Future<void> restoreSession() async {
    final barber = await _getCurrentBarberUseCase();
    if (barber != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, barber: barber));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
