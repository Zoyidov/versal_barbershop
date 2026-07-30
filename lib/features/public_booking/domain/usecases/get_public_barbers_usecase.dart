import '../entities/public_barber.dart';
import '../repositories/public_booking_repository.dart';

class GetPublicBarbersUseCase {
  final PublicBookingRepository _repository;

  GetPublicBarbersUseCase(this._repository);

  Future<List<PublicBarber>> call() => _repository.getBarbers();
}
