import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl({required AdminRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<ManagedUser>> watchUsers() => _remoteDataSource.watchUsers();

  @override
  Future<void> approveBarber({required String uid, required int smsLimit}) =>
      _remoteDataSource.approveBarber(uid: uid, smsLimit: smsLimit);

  @override
  Future<void> setSmsLimit({required String uid, required int smsLimit}) =>
      _remoteDataSource.setSmsLimit(uid: uid, smsLimit: smsLimit);

  @override
  Future<void> setUserActive({required String uid, required bool active}) =>
      _remoteDataSource.setUserActive(uid: uid, active: active);

  @override
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour}) =>
      _remoteDataSource.updateScheduleHours(uid: uid, startHour: startHour, endHour: endHour);
}
