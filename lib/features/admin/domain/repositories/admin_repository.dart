import '../entities/managed_user.dart';

abstract class AdminRepository {
  Stream<List<ManagedUser>> watchUsers();
  Future<void> approveBarber({required String uid, required int smsLimit});
  Future<void> setSmsLimit({required String uid, required int smsLimit});
  Future<void> setUserActive({required String uid, required bool active});
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour});
}
