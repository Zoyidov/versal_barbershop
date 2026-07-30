import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/usecases/approve_barber_usecase.dart';
import '../../domain/usecases/set_sms_limit_usecase.dart';
import '../../domain/usecases/set_user_active_usecase.dart';
import '../../domain/usecases/update_barber_schedule_usecase.dart';
import '../../domain/usecases/watch_users_usecase.dart';

part 'user_management_state.dart';

/// Drives the admin-only user-management screen: the live `users` list
/// (pending registrations + approved barbers) plus the approve/limit/
/// activate/schedule actions, each backed by an admin-only Cloud Function
/// (or, for schedule hours, a directly rules-permitted Firestore write).
class UserManagementCubit extends Cubit<UserManagementState> {
  final WatchUsersUseCase _watchUsersUseCase;
  final ApproveBarberUseCase _approveBarberUseCase;
  final SetSmsLimitUseCase _setSmsLimitUseCase;
  final SetUserActiveUseCase _setUserActiveUseCase;
  final UpdateBarberScheduleUseCase _updateBarberScheduleUseCase;

  StreamSubscription<List<ManagedUser>>? _subscription;

  UserManagementCubit({
    required WatchUsersUseCase watchUsersUseCase,
    required ApproveBarberUseCase approveBarberUseCase,
    required SetSmsLimitUseCase setSmsLimitUseCase,
    required SetUserActiveUseCase setUserActiveUseCase,
    required UpdateBarberScheduleUseCase updateBarberScheduleUseCase,
  }) : _watchUsersUseCase = watchUsersUseCase,
       _approveBarberUseCase = approveBarberUseCase,
       _setSmsLimitUseCase = setSmsLimitUseCase,
       _setUserActiveUseCase = setUserActiveUseCase,
       _updateBarberScheduleUseCase = updateBarberScheduleUseCase,
       super(const UserManagementState()) {
    _subscribe();
  }

  /// Re-subscribes and waits for the next snapshot, for pull-to-refresh.
  /// The list is already real-time (Firestore pushes updates on its own),
  /// so this exists to give the gesture a concrete round-trip to await and
  /// a moment of visible feedback rather than resolving instantly.
  Future<void> refresh() {
    final completer = Completer<void>();
    _subscribe(completer: completer);
    return completer.future;
  }

  void _subscribe({Completer<void>? completer}) {
    _subscription?.cancel();
    _subscription = _watchUsersUseCase().listen(
      (users) {
        emit(
          state.copyWith(
            status: UsersStatus.loaded,
            users: users,
            clearError: true,
          ),
        );
        if (completer != null && !completer.isCompleted) completer.complete();
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: UsersStatus.error,
            errorMessage: error is AppException
                ? error.message
                : 'Foydalanuvchilarni yuklab bo\'lmadi.',
          ),
        );
        if (completer != null && !completer.isCompleted) completer.complete();
      },
    );
  }

  Future<void> approve({required String uid, required int smsLimit}) async {
    emit(state.copyWith(busyUid: uid, clearError: true));
    try {
      await _approveBarberUseCase(uid: uid, smsLimit: smsLimit);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } finally {
      emit(state.copyWith(clearBusy: true));
    }
  }

  Future<void> updateSmsLimit({
    required String uid,
    required int smsLimit,
  }) async {
    emit(state.copyWith(busyUid: uid, clearError: true));
    try {
      await _setSmsLimitUseCase(uid: uid, smsLimit: smsLimit);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } finally {
      emit(state.copyWith(clearBusy: true));
    }
  }

  Future<void> setActive({required String uid, required bool active}) async {
    emit(state.copyWith(busyUid: uid, clearError: true));
    try {
      await _setUserActiveUseCase(uid: uid, active: active);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } finally {
      emit(state.copyWith(clearBusy: true));
    }
  }

  Future<void> updateScheduleHours({
    required String uid,
    required int startHour,
    required int endHour,
  }) async {
    emit(state.copyWith(busyUid: uid, clearError: true));
    try {
      await _updateBarberScheduleUseCase(
        uid: uid,
        startHour: startHour,
        endHour: endHour,
      );
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } finally {
      emit(state.copyWith(clearBusy: true));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
