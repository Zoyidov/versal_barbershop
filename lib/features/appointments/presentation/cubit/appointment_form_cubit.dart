import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/client_history.dart';
import '../../domain/usecases/cancel_appointment_usecase.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/get_client_history_usecase.dart';
import '../../domain/usecases/update_appointment_usecase.dart';

part 'appointment_form_state.dart';

/// Backs the add/edit appointment screen: field state, the debounced
/// smart-alert phone lookup, and create/update/cancel submission.
class AppointmentFormCubit extends Cubit<AppointmentFormState> {
  final CreateAppointmentUseCase _createAppointmentUseCase;
  final UpdateAppointmentUseCase _updateAppointmentUseCase;
  final GetClientHistoryUseCase _getClientHistoryUseCase;
  final CancelAppointmentUseCase _cancelAppointmentUseCase;

  Timer? _debounce;

  AppointmentFormCubit({
    required CreateAppointmentUseCase createAppointmentUseCase,
    required UpdateAppointmentUseCase updateAppointmentUseCase,
    required GetClientHistoryUseCase getClientHistoryUseCase,
    required CancelAppointmentUseCase cancelAppointmentUseCase,
  })  : _createAppointmentUseCase = createAppointmentUseCase,
        _updateAppointmentUseCase = updateAppointmentUseCase,
        _getClientHistoryUseCase = getClientHistoryUseCase,
        _cancelAppointmentUseCase = cancelAppointmentUseCase,
        super(AppointmentFormState(day: DateTime.now()));

  /// Called once when the form opens. [defaultDay] is the day currently
  /// selected on the dashboard; [existing] is non-null when editing.
  void init({required DateTime defaultDay, Appointment? existing}) {
    if (existing == null) {
      emit(AppointmentFormState(day: defaultDay));
      return;
    }
    emit(AppointmentFormState(
      mode: AppointmentFormMode.edit,
      existing: existing,
      phoneNumber: existing.clientPhone,
      clientName: existing.clientName ?? '',
      serviceType: existing.serviceType,
      day: existing.appointmentTime,
      time: TimeOfDay.fromDateTime(existing.appointmentTime),
      sendSms: existing.sendSms,
    ));
    // Still surface prior-cancellation history for context when editing.
    _lookupHistory(existing.clientPhone);
  }

  void onPhoneChanged(String value) {
    emit(state.copyWith(
      phoneNumber: value,
      clearPhoneError: true,
      clearClientHistory: true,
      historyStatus: ClientHistoryLookupStatus.idle,
    ));

    _debounce?.cancel();
    final normalized = Validators.normalizePhone(value);
    if (normalized == null) return;

    _debounce = Timer(const Duration(milliseconds: 500), () => _lookupHistory(normalized));
  }

  Future<void> _lookupHistory(String normalizedPhone) async {
    emit(state.copyWith(historyStatus: ClientHistoryLookupStatus.loading));
    try {
      final history = await _getClientHistoryUseCase(normalizedPhone);
      if (isClosed) return;
      if (history == null) {
        emit(state.copyWith(historyStatus: ClientHistoryLookupStatus.notFound, clearClientHistory: true));
      } else {
        // Pre-fill the name from history only if the barber hasn't typed
        // one yet, so we don't clobber an intentional edit.
        final prefillName = state.clientName.trim().isEmpty ? (history.lastName ?? '') : state.clientName;
        emit(state.copyWith(
          historyStatus: ClientHistoryLookupStatus.found,
          clientHistory: history,
          clientName: prefillName,
        ));
      }
    } on AppException {
      if (isClosed) return;
      emit(state.copyWith(historyStatus: ClientHistoryLookupStatus.idle));
    }
  }

  void onNameChanged(String value) => emit(state.copyWith(clientName: value));

  void onServiceTypeSelected(String? serviceType) {
    if (serviceType == null || serviceType == state.serviceType) {
      emit(state.copyWith(clearServiceType: true));
    } else {
      emit(state.copyWith(serviceType: serviceType));
    }
  }

  void onDaySelected(DateTime day) => emit(state.copyWith(day: day));

  void onTimeSelected(TimeOfDay time) => emit(state.copyWith(time: time));

  void toggleSendSms(bool value) => emit(state.copyWith(sendSms: value));

  Future<void> submit() async {
    final normalizedPhone = Validators.normalizePhone(state.phoneNumber);
    if (normalizedPhone == null) {
      emit(state.copyWith(phoneError: 'Yaroqli telefon raqami kiritilishi shart'));
      return;
    }
    if (state.time == null) {
      emit(state.copyWith(errorMessage: 'Iltimos, uchrashuv vaqtini tanlang.'));
      return;
    }

    final barberId = FirebaseAuth.instance.currentUser?.uid;
    if (barberId == null) {
      emit(state.copyWith(errorMessage: 'Sessiya muddati tugadi. Iltimos, qayta kiring.'));
      return;
    }

    final appointmentTime = DateTime(
      state.day.year,
      state.day.month,
      state.day.day,
      state.time!.hour,
      state.time!.minute,
    );

    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final name = state.clientName.trim();
      if (state.isEditing) {
        final updated = state.existing!.copyWith(
          clientPhone: normalizedPhone,
          clientName: name.isEmpty ? null : name,
          serviceType: state.serviceType,
          appointmentTime: appointmentTime,
          sendSms: state.sendSms,
        );
        await _updateAppointmentUseCase(updated);
      } else {
        final appointment = Appointment(
          clientPhone: normalizedPhone,
          clientName: name.isEmpty ? null : name,
          serviceType: state.serviceType,
          barberId: barberId,
          appointmentTime: appointmentTime,
          sendSms: state.sendSms,
          createdAt: DateTime.now(),
        );
        await _createAppointmentUseCase(appointment);
      }
      emit(state.copyWith(submitting: false, saved: true));
    } on AppException catch (e) {
      emit(state.copyWith(submitting: false, errorMessage: e.message));
    }
  }

  Future<void> cancelAppointment() async {
    final id = state.existing?.id;
    if (id == null) return;
    emit(state.copyWith(cancelling: true, clearError: true));
    try {
      await _cancelAppointmentUseCase(id);
      emit(state.copyWith(cancelling: false, cancelled: true));
    } on AppException catch (e) {
      emit(state.copyWith(cancelling: false, errorMessage: e.message));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
