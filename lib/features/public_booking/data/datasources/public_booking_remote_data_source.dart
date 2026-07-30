import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/day_slots.dart';
import '../../domain/entities/public_barber.dart';

abstract class PublicBookingRemoteDataSource {
  Future<List<PublicBarber>> getBarbers();
  Future<DaySlots> getDaySlots(DateTime day, {required String barberId});
  Future<void> createBooking({
    required DateTime day,
    required int hour,
    required String barberId,
    required String clientName,
    required String clientPhone,
  });
}

/// Talks to the `getPublicDaySlots` / `createPublicBooking` callables
/// (`functions/src/publicBooking.ts`) rather than Firestore directly - the
/// public booking screen has no Firebase Auth session, and
/// `firestore.rules` locks both `appointments` and `settings` to signed-in
/// barbers, so a Cloud Function running under the Admin SDK is the only way
/// an anonymous client can read availability or create a booking.
class PublicBookingRemoteDataSourceImpl implements PublicBookingRemoteDataSource {
  final FirebaseFunctions _functions;

  PublicBookingRemoteDataSourceImpl({required FirebaseFunctions functions}) : _functions = functions;

  @override
  Future<List<PublicBarber>> getBarbers() async {
    try {
      final callable = _functions.httpsCallable('getPublicBarbers');
      final result = await callable.call<Map<String, dynamic>>();
      final rawBarbers = (result.data['barbers'] as List).cast<Map<dynamic, dynamic>>();
      return rawBarbers
          .map((b) => PublicBarber(uid: b['uid'] as String, name: b['name'] as String? ?? ''))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'Sartaroshlar ro\'yxatini yuklab bo\'lmadi.');
    } catch (e) {
      throw AppException('Sartaroshlar ro\'yxatini yuklab bo\'lmadi: $e');
    }
  }

  @override
  Future<DaySlots> getDaySlots(DateTime day, {required String barberId}) async {
    try {
      final callable = _functions.httpsCallable('getPublicDaySlots');
      final result = await callable.call<Map<String, dynamic>>({
        'year': day.year,
        'month': day.month,
        'day': day.day,
        'barberId': barberId,
      });
      final data = result.data;
      final rawSlots = (data['slots'] as List).cast<Map<dynamic, dynamic>>();
      return DaySlots(
        startHour: (data['startHour'] as num).toInt(),
        endHour: (data['endHour'] as num).toInt(),
        slots: rawSlots
            .map((s) => TimeSlot(
                  hour: (s['hour'] as num).toInt(),
                  isFree: s['isFree'] as bool,
                  isPast: s['isPast'] as bool,
                ))
            .toList(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'Bo\'sh vaqtlarni yuklab bo\'lmadi.');
    } catch (e) {
      throw AppException('Bo\'sh vaqtlarni yuklab bo\'lmadi: $e');
    }
  }

  @override
  Future<void> createBooking({
    required DateTime day,
    required int hour,
    required String barberId,
    required String clientName,
    required String clientPhone,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPublicBooking');
      await callable.call<Map<String, dynamic>>({
        'year': day.year,
        'month': day.month,
        'day': day.day,
        'hour': hour,
        'barberId': barberId,
        'clientName': clientName,
        'clientPhone': clientPhone,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'Band qilishda xatolik yuz berdi.');
    } catch (e) {
      throw AppException('Band qilishda xatolik yuz berdi: $e');
    }
  }
}
