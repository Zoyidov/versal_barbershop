import '../entities/day_slots.dart';
import '../repositories/public_booking_repository.dart';

class GetPublicDaySlotsUseCase {
  final PublicBookingRepository _repository;

  GetPublicDaySlotsUseCase(this._repository);

  Future<DaySlots> call(DateTime day) => _repository.getDaySlots(day);
}
