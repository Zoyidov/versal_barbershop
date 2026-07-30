import '../../domain/entities/day_slots.dart';
import '../../domain/entities/public_barber.dart';
import '../../domain/repositories/public_booking_repository.dart';
import '../datasources/public_booking_remote_data_source.dart';

class PublicBookingRepositoryImpl implements PublicBookingRepository {
  final PublicBookingRemoteDataSource _remoteDataSource;

  PublicBookingRepositoryImpl({required PublicBookingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<PublicBarber>> getBarbers() => _remoteDataSource.getBarbers();

  @override
  Future<DaySlots> getDaySlots(DateTime day, {required String barberId}) =>
      _remoteDataSource.getDaySlots(day, barberId: barberId);

  @override
  Future<void> createBooking({
    required DateTime day,
    required int hour,
    required String barberId,
    required String clientName,
    required String clientPhone,
  }) {
    return _remoteDataSource.createBooking(
      day: day,
      hour: hour,
      barberId: barberId,
      clientName: clientName,
      clientPhone: clientPhone,
    );
  }
}
