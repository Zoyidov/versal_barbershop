import '../repositories/admin_repository.dart';

class SetSmsLimitUseCase {
  final AdminRepository _repository;

  SetSmsLimitUseCase(this._repository);

  Future<void> call({required String uid, required int smsLimit}) =>
      _repository.setSmsLimit(uid: uid, smsLimit: smsLimit);
}
