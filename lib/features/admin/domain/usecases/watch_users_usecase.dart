import '../entities/managed_user.dart';
import '../repositories/admin_repository.dart';

class WatchUsersUseCase {
  final AdminRepository _repository;

  WatchUsersUseCase(this._repository);

  Stream<List<ManagedUser>> call() => _repository.watchUsers();
}
