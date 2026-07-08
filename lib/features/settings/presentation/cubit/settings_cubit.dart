import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/update_reminder_window_usecase.dart';
import '../../domain/usecases/update_schedule_hours_usecase.dart';
import '../../domain/usecases/watch_settings_usecase.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final WatchSettingsUseCase _watchSettingsUseCase;
  final UpdateReminderWindowUseCase _updateReminderWindowUseCase;
  final UpdateScheduleHoursUseCase _updateScheduleHoursUseCase;
  StreamSubscription<AppSettings>? _subscription;

  SettingsCubit({
    required WatchSettingsUseCase watchSettingsUseCase,
    required UpdateReminderWindowUseCase updateReminderWindowUseCase,
    required UpdateScheduleHoursUseCase updateScheduleHoursUseCase,
  })  : _watchSettingsUseCase = watchSettingsUseCase,
        _updateReminderWindowUseCase = updateReminderWindowUseCase,
        _updateScheduleHoursUseCase = updateScheduleHoursUseCase,
        super(const SettingsState()) {
    _subscription = _watchSettingsUseCase().listen(
      (settings) => emit(state.copyWith(status: SettingsStatus.loaded, settings: settings)),
      onError: (error) {
        final message = error is AppException ? error.message : 'Sozlamalarni yuklab bo\'lmadi.';
        emit(state.copyWith(status: SettingsStatus.error, errorMessage: message));
      },
    );
  }

  Future<void> updateReminderWindow(int minutes) async {
    emit(state.copyWith(saving: true, clearError: true, saved: false));
    try {
      await _updateReminderWindowUseCase(minutes);
      emit(state.copyWith(saving: false, saved: true, savedTarget: SettingsSaveTarget.reminderWindow));
    } on AppException catch (e) {
      emit(state.copyWith(saving: false, errorMessage: e.message));
    }
  }

  Future<void> updateScheduleHours(int startHour, int endHour) async {
    emit(state.copyWith(saving: true, clearError: true, saved: false));
    try {
      await _updateScheduleHoursUseCase(startHour, endHour);
      emit(state.copyWith(saving: false, saved: true, savedTarget: SettingsSaveTarget.scheduleHours));
    } on AppException catch (e) {
      emit(state.copyWith(saving: false, errorMessage: e.message));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
