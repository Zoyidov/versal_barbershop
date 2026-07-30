import '../entities/barber.dart';
import '../repositories/auth_repository.dart';

/// Live profile of a specific barber (self or, for an admin caller, any
/// other barber) - see [AuthRepository.watchBarberProfile].
class WatchBarberProfileUseCase {
  final AuthRepository _repository;

  WatchBarberProfileUseCase(this._repository);

  Stream<Barber?> call(String uid) => _repository.watchBarberProfile(uid);
}
