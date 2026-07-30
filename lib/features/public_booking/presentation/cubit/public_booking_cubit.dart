import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/day_slots.dart';
import '../../domain/entities/public_barber.dart';
import '../../domain/usecases/create_public_booking_usecase.dart';
import '../../domain/usecases/get_public_barbers_usecase.dart';
import '../../domain/usecases/get_public_day_slots_usecase.dart';

part 'public_booking_state.dart';

/// Backs the client-facing booking screen: loads the barber list, then one
/// day's free/busy hourly slots for whichever barber is selected, and
/// submits a walk-in's name/phone against an open hour with that barber.
class PublicBookingCubit extends Cubit<PublicBookingState> {
  final GetPublicBarbersUseCase _getBarbersUseCase;
  final GetPublicDaySlotsUseCase _getDaySlotsUseCase;
  final CreatePublicBookingUseCase _createBookingUseCase;

  PublicBookingCubit({
    required GetPublicBarbersUseCase getBarbersUseCase,
    required GetPublicDaySlotsUseCase getDaySlotsUseCase,
    required CreatePublicBookingUseCase createBookingUseCase,
  })  : _getBarbersUseCase = getBarbersUseCase,
        _getDaySlotsUseCase = getDaySlotsUseCase,
        _createBookingUseCase = createBookingUseCase,
        super(PublicBookingState()) {
    _loadBarbers();
  }

  Future<void> _loadBarbers() async {
    emit(state.copyWith(barbersLoading: true));
    try {
      final barbers = await _getBarbersUseCase();
      emit(state.copyWith(barbersLoading: false, barbers: barbers));
      if (barbers.isNotEmpty) {
        await selectBarber(barbers.first.uid);
      } else {
        emit(state.copyWith(status: PublicBookingStatus.error, errorMessage: 'Hozircha sartaroshlar mavjud emas.'));
      }
    } on AppException catch (e) {
      emit(state.copyWith(barbersLoading: false, status: PublicBookingStatus.error, errorMessage: e.message));
    }
  }

  Future<void> selectBarber(String barberId) async {
    emit(state.copyWith(selectedBarberId: barberId));
    await loadSlots();
  }

  Future<void> selectDay(DateTime day) async {
    emit(state.copyWith(selectedDay: day));
    await loadSlots();
  }

  Future<void> loadSlots() async {
    final barberId = state.selectedBarberId;
    if (barberId == null) return;
    emit(state.copyWith(status: PublicBookingStatus.loading));
    try {
      final daySlots = await _getDaySlotsUseCase(state.selectedDay, barberId: barberId);
      emit(state.copyWith(status: PublicBookingStatus.loaded, daySlots: daySlots));
    } on AppException catch (e) {
      emit(state.copyWith(status: PublicBookingStatus.error, errorMessage: e.message));
    }
  }

  /// Returns true on success. On failure (most commonly: someone else took
  /// the slot first) the slots are refreshed so the UI reflects reality.
  Future<bool> book({required int hour, required String name, required String phone}) async {
    final barberId = state.selectedBarberId;
    if (barberId == null) return false;
    emit(state.copyWith(isSubmitting: true));
    try {
      await _createBookingUseCase(
        day: state.selectedDay,
        hour: hour,
        barberId: barberId,
        clientName: name,
        clientPhone: phone,
      );
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
