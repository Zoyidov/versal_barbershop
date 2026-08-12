import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../statistics/domain/entities/client_stat.dart';
import '../../../statistics/domain/usecases/search_clients_usecase.dart';
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
  final SearchClientsUseCase _searchClientsUseCase;

  Timer? _debounce;
  Timer? _suggestionDebounce;

  AppointmentFormCubit({
    required CreateAppointmentUseCase createAppointmentUseCase,
    required UpdateAppointmentUseCase updateAppointmentUseCase,
    required GetClientHistoryUseCase getClientHistoryUseCase,
    required CancelAppointmentUseCase cancelAppointmentUseCase,
    required SearchClientsUseCase searchClientsUseCase,
  })  : _createAppointmentUseCase = createAppointmentUseCase,
        _updateAppointmentUseCase = updateAppointmentUseCase,
        _getClientHistoryUseCase = getClientHistoryUseCase,
        _cancelAppointmentUseCase = cancelAppointmentUseCase,
        _searchClientsUseCase = searchClientsUseCase,
        super(AppointmentFormState(day: DateTime.now()));

  /// Called once when the form opens. [defaultDay] is the day currently
  /// selected on the dashboard; [defaultTime] is pre-filled when the form
  /// was opened from a specific hour slot on the timetable; [existing] is
  /// non-null when editing.
  void init({required DateTime defaultDay, TimeOfDay? defaultTime, Appointment? existing}) {
    if (existing == null) {
      emit(AppointmentFormState(day: defaultDay, time: defaultTime));
      return;
    }
    emit(AppointmentFormState(
      mode: AppointmentFormMode.edit,
      existing: existing,
      phoneNumber: existing.clientPhone ?? '',
      clientName: existing.clientName ?? '',
      serviceType: existing.serviceType,
      day: existing.appointmentTime,
      time: TimeOfDay.fromDateTime(existing.appointmentTime),
      sendSms: existing.sendSms,
    ));
    // Still surface prior-cancellation history for context when editing.
    final existingPhone = existing.clientPhone;
    if (existingPhone != null) _lookupHistory(existingPhone);
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
    if (normalized != null) {
      _debounce = Timer(const Duration(milliseconds: 500), () => _lookupHistory(normalized));
    }

    _suggestionDebounce?.cancel();
    final localDigits = value.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^998'), '');
    if (localDigits.length < 2) {
      emit(state.copyWith(phoneSuggestions: const []));
      return;
    }
    _suggestionDebounce = Timer(const Duration(milliseconds: 300), () => _searchSuggestions(value));
  }

  Future<void> _searchSuggestions(String query) async {
    try {
      final barberId = FirebaseAuth.instance.currentUser?.uid;
      final results = await _searchClientsUseCase(query, barberId: barberId);
      if (isClosed || state.phoneNumber != query) return;
      emit(state.copyWith(phoneSuggestions: results.take(5).toList()));
    } on AppException {
      // Suggestions are a convenience, not essential - a failed lookup just
      // means none are shown, same as no matches found.
      if (isClosed) return;
      emit(state.copyWith(phoneSuggestions: const []));
    }
  }

  /// Fills the phone (and, if not already typed, the name) from a tapped
  /// suggestion and immediately looks up its cancellation history, skipping
  /// the usual typing debounce since the number is already known-good.
  void selectClientSuggestion(ClientStat client) {
    _debounce?.cancel();
    _suggestionDebounce?.cancel();
    final prefillName = state.clientName.trim().isEmpty ? (client.lastName ?? '') : state.clientName;
    emit(state.copyWith(
      phoneNumber: client.phoneNumber,
      clientName: prefillName,
      clearPhoneError: true,
      phoneSuggestions: const [],
    ));
    _lookupHistory(client.phoneNumber);
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
    // Phone is optional - a client can be added with just a name - but a
    // non-empty phone field still has to be a valid number, and at least
    // one of phone/name has to be there to identify the client by.
    final phoneRaw = state.phoneNumber.trim();
    String? normalizedPhone;
    if (phoneRaw.isNotEmpty) {
      normalizedPhone = Validators.normalizePhone(phoneRaw);
      if (normalizedPhone == null) {
        emit(state.copyWith(phoneError: 'Yaroqli telefon raqami kiritilishi shart'));
        return;
      }
    }
    final name = state.clientName.trim();
    if (normalizedPhone == null && name.isEmpty) {
      emit(state.copyWith(errorMessage: 'Ism yoki telefon raqami kiritilishi shart.'));
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

    // Can't send a reminder with nothing to send it to.
    final sendSms = normalizedPhone != null && state.sendSms;

    emit(state.copyWith(submitting: true, clearError: true));
    try {
      if (state.isEditing) {
        final updated = state.existing!.copyWith(
          clientPhone: normalizedPhone,
          clearClientPhone: normalizedPhone == null,
          clientName: name.isEmpty ? null : name,
          clearClientName: name.isEmpty,
          serviceType: state.serviceType,
          appointmentTime: appointmentTime,
          sendSms: sendSms,
        );
        await _updateAppointmentUseCase(updated);
      } else {
        final appointment = Appointment(
          clientPhone: normalizedPhone,
          clientName: name.isEmpty ? null : name,
          serviceType: state.serviceType,
          barberId: barberId,
          appointmentTime: appointmentTime,
          sendSms: sendSms,
          createdAt: DateTime.now(),
        );
        await _createAppointmentUseCase(appointment);
      }
      emit(state.copyWith(submitting: false, saved: true));
    } on AppException catch (e) {
      debugPrint('[AppointmentFormCubit] submit() failed with AppException: ${e.message}');
      emit(state.copyWith(submitting: false, errorMessage: e.message));
    } catch (e, stackTrace) {
      debugPrint('[AppointmentFormCubit] submit() failed with unexpected error: $e');
      debugPrint('$stackTrace');
      emit(state.copyWith(submitting: false, errorMessage: 'Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.'));
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
    _suggestionDebounce?.cancel();
    return super.close();
  }
}
