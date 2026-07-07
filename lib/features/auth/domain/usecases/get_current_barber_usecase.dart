import '../entities/barber.dart';
import '../repositories/auth_repository.dart';

class GetCurrentBarberUseCase {
  final AuthRepository _repository;

  GetCurrentBarberUseCase(this._repository);

  Future<Barber?> call() => _repository.getCurrentBarber();
}
