import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../domain/entities/barber.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_barber_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

part 'auth_state.dart';

/// Drives the whole app's authentication gate. [RootShell] listens to this
/// cubit to decide whether to show the login screen or the bottom-nav shell.
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentBarberUseCase _getCurrentBarberUseCase;
  final AuthRepository _authRepository;
  final PushNotificationService _pushNotificationService;

  StreamSubscription<Barber?>? _authSubscription;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentBarberUseCase getCurrentBarberUseCase,
    required AuthRepository authRepository,
    required PushNotificationService pushNotificationService,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentBarberUseCase = getCurrentBarberUseCase,
        _authRepository = authRepository,
        _pushNotificationService = pushNotificationService,
        super(const AuthState()) {
    _bootstrap();
  }

  void _bootstrap() {
    _authSubscription = _authRepository.watchAuthState().listen((barber) {
      if (barber != null) {
        // Only (re-)register the push token on an actual sign-in - this
        // listener also re-fires on every unrelated profile change (an
        // admin topping up smsLimit, etc, since it's a live Firestore
        // stream), and re-registering there would be redundant.
        final isNewSession = state.barber?.uid != barber.uid;
        emit(state.copyWith(status: AuthStatus.authenticated, barber: barber, clearError: true));
        if (isNewSession && isPushCapablePlatform) {
          _pushNotificationService.registerForUser(barber.uid);
        }
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

  Future<void> register({required String phoneNumber, required String password, required String name}) async {
    debugPrint('[AuthCubit] register() started for phoneNumber=$phoneNumber');
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final barber = await _registerUseCase(phoneNumber: phoneNumber, password: password, name: name);
      debugPrint('[AuthCubit] register() succeeded for uid=${barber.uid}');
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        barber: barber,
        submitting: false,
        clearError: true,
      ));
    } on AppException catch (e) {
      debugPrint('[AuthCubit] register() failed with AppException: ${e.message}');
      emit(state.copyWith(submitting: false, errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('[AuthCubit] register() failed with unexpected error: $e');
      debugPrint('$stackTrace');
      emit(state.copyWith(submitting: false, errorMessage: 'Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.'));
    }
  }

  Future<void> logout() async {
    if (isPushCapablePlatform) await _pushNotificationService.unregisterCurrentUser();
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

  /// Re-fetches the current barber's profile, so a user waiting on the
  /// pending-approval screen can check whether an admin has approved them
  /// yet without signing out and back in.
  Future<void> refreshCurrentBarber() async {
    final barber = await _getCurrentBarberUseCase();
    if (barber != null) {
      emit(state.copyWith(barber: barber));
    }
  }

  /// Sets the signed-in barber's own working hours. The live profile stream
  /// from [_bootstrap] picks up the change and re-emits automatically, so
  /// there's no need to manually refresh [state] here.
  Future<void> updateOwnScheduleHours({required int startHour, required int endHour}) async {
    final uid = state.barber?.uid;
    if (uid == null) return;
    try {
      await _authRepository.updateScheduleHours(uid: uid, startHour: startHour, endHour: endHour);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
