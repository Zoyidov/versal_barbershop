import '../entities/day_slots.dart';

abstract class PublicBookingRepository {
  /// Free/busy hourly breakdown for one day, computed server-side.
  Future<DaySlots> getDaySlots(DateTime day);

  /// Books the given hour on [day] for a walk-in client. Throws
  /// [AppException] (via the data source) if the slot was taken in the
  /// meantime or the input is invalid.
  Future<void> createBooking({
    required DateTime day,
    required int hour,
    required String clientName,
    required String clientPhone,
  });
}
