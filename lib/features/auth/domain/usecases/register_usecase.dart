import '../entities/barber.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Barber> call({required String phoneNumber, required String password, required String name}) {
    return _repository.register(phoneNumber: phoneNumber, password: password, name: name);
  }
}
