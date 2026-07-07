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
  Future<void> logout() => _remoteDataSource.logout();

  @override
  Stream<Barber?> watchAuthState() => _remoteDataSource.watchAuthState();

  @override
  Future<Barber?> getCurrentBarber() => _remoteDataSource.getCurrentBarber();
}
