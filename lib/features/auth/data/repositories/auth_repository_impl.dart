import '../../domain/entities/barber.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Barber> login({required String phoneNumber, required String password}) {
    return _remoteDataSource.login(phoneNumber: phoneNumber, password: password);
  }

  @override
  Future<Barber> register({required String phoneNumber, required String password, required String name}) {
    return _remoteDataSource.register(phoneNumber: phoneNumber, password: password, name: name);
  }

  @override
  Future<void> logout() => _remoteDataSource.logout();

  @override
  Stream<Barber?> watchAuthState() => _remoteDataSource.watchAuthState();

  @override
  Future<Barber?> getCurrentBarber() => _remoteDataSource.getCurrentBarber();

  @override
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour}) {
    return _remoteDataSource.updateScheduleHours(uid: uid, startHour: startHour, endHour: endHour);
  }

  @override
  Stream<Barber?> watchBarberProfile(String uid) => _remoteDataSource.watchBarberProfile(uid);
}
