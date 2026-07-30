import '../repositories/public_booking_repository.dart';

class CreatePublicBookingUseCase {
  final PublicBookingRepository _repository;

  CreatePublicBookingUseCase(this._repository);

  Future<void> call({
    required DateTime day,
    required int hour,
    required String barberId,
    required String clientName,
    required String clientPhone,
  }) {
    return _repository.createBooking(
      day: day,
      hour: hour,
      barberId: barberId,
      clientName: clientName,
      clientPhone: clientPhone,
    );
  }
}
