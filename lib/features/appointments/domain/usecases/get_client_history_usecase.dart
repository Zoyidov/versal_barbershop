import '../entities/client_history.dart';
import '../repositories/appointment_repository.dart';

class GetClientHistoryUseCase {
  final AppointmentRepository _repository;

  GetClientHistoryUseCase(this._repository);

  Future<ClientHistory?> call(String phoneNumber) => _repository.getClientHistory(phoneNumber);
}
