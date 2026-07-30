import '../repositories/admin_repository.dart';

class ApproveBarberUseCase {
  final AdminRepository _repository;

  ApproveBarberUseCase(this._repository);

  Future<void> call({required String uid, required int smsLimit}) =>
      _repository.approveBarber(uid: uid, smsLimit: smsLimit);
}
