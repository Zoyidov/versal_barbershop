import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/day_slots.dart';
import '../../domain/usecases/create_public_booking_usecase.dart';
import '../../domain/usecases/get_public_day_slots_usecase.dart';

part 'public_booking_state.dart';

/// Backs the client-facing booking screen: loads one day's free/busy hourly
/// slots and submits a walk-in's name/phone against an open hour.
class PublicBookingCubit extends Cubit<PublicBookingState> {
  final GetPublicDaySlotsUseCase _getDaySlotsUseCase;
  final CreatePublicBookingUseCase _createBookingUseCase;

  PublicBookingCubit({
    required GetPublicDaySlotsUseCase getDaySlotsUseCase,
    required CreatePublicBookingUseCase createBookingUseCase,
  })  : _getDaySlotsUseCase = getDaySlotsUseCase,
        _createBookingUseCase = createBookingUseCase,
        super(PublicBookingState()) {
    loadSlots();
  }

  Future<void> selectDay(DateTime day) async {
    emit(state.copyWith(selectedDay: day));
    await loadSlots();
  }

  Future<void> loadSlots() async {
    emit(state.copyWith(status: PublicBookingStatus.loading));
    try {
      final daySlots = await _getDaySlotsUseCase(state.selectedDay);
      emit(state.copyWith(status: PublicBookingStatus.loaded, daySlots: daySlots));
    } on AppException catch (e) {
      emit(state.copyWith(status: PublicBookingStatus.error, errorMessage: e.message));
    }
  }

  /// Returns true on success. On failure (most commonly: someone else took
  /// the slot first) the slots are refreshed so the UI reflects reality.
  Future<bool> book({required int hour, required String name, required String phone}) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await _createBookingUseCase(day: state.selectedDay, hour: hour, clientName: name, clientPhone: phone);
      emit(state.copyWith(isSubmitting: false));
      await loadSlots();
      return true;
    } on AppException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
      await loadSlots();
      return false;
    }
  }
}
