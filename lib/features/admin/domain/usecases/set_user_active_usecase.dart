import '../repositories/admin_repository.dart';

class SetUserActiveUseCase {
  final AdminRepository _repository;

  SetUserActiveUseCase(this._repository);

  Future<void> call({required String uid, required bool active}) =>
      _repository.setUserActive(uid: uid, active: active);
}
