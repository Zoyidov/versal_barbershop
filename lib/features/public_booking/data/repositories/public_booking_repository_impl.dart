import '../../domain/entities/day_slots.dart';
import '../../domain/repositories/public_booking_repository.dart';
import '../datasources/public_booking_remote_data_source.dart';

class PublicBookingRepositoryImpl implements PublicBookingRepository {
  final PublicBookingRemoteDataSource _remoteDataSource;

  PublicBookingRepositoryImpl({required PublicBookingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<DaySlots> getDaySlots(DateTime day) => _remoteDataSource.getDaySlots(day);

  @override
  Future<void> createBooking({
    required DateTime day,
    required int hour,
    required String clientName,
    required String clientPhone,
  }) {
    return _remoteDataSource.createBooking(day: day, hour: hour, clientName: clientName, clientPhone: clientPhone);
  }
}
