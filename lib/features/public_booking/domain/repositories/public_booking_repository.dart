import '../entities/day_slots.dart';
import '../entities/public_barber.dart';

abstract class PublicBookingRepository {
  /// Every barber a walk-in client can currently pick from.
  Future<List<PublicBarber>> getBarbers();

  /// Free/busy hourly breakdown for one day, for one barber, computed
  /// server-side.
  Future<DaySlots> getDaySlots(DateTime day, {required String barberId});

  /// Books the given hour on [day] with [barberId] for a walk-in client.
  /// Throws [AppException] (via the data source) if the slot was taken in
  /// the meantime or the input is invalid.
  Future<void> createBooking({
    required DateTime day,
    required int hour,
    required String barberId,
    required String clientName,
    required String clientPhone,
  });
}
