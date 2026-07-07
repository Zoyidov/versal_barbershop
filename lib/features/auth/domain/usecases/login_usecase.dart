import '../entities/barber.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Barber> call({required String phoneNumber, required String password}) {
    return _repository.login(phoneNumber: phoneNumber, password: password);
  }
}
