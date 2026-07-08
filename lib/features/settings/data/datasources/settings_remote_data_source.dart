import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/sms_balance.dart';
import '../models/app_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Stream<AppSettingsModel> watchSettings();
  Future<void> updateReminderWindow(int minutes);
  Future<void> updateScheduleHours(int startHour, int endHour);
  Future<SmsBalance> getSmsBalance();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  SettingsRemoteDataSourceImpl({required FirebaseFirestore firestore, required FirebaseFunctions functions})
      : _firestore = firestore,
        _functions = functions;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(FirestorePaths.settings).doc(FirestorePaths.globalSettingsDoc);

  @override
  Stream<AppSettingsModel> watchSettings() {
    return _doc.snapshots().map(AppSettingsModel.fromSnapshot).handleError((error) {
      throw AppException('Sozlamalarni yuklab bo\'lmadi: $error');
    });
  }

  @override
  Future<void> updateReminderWindow(int minutes) async {
    try {
      await _doc.set({
        SettingsFields.reminderWindowMinutes: minutes,
        SettingsFields.updatedAt: FieldValue.serverTimestamp(),
        SettingsFields.updatedBy: FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
    } catch (e) {
      throw AppException('Eslatma vaqtini yangilab bo\'lmadi: $e');
    }
  }

  @override
  Future<void> updateScheduleHours(int startHour, int endHour) async {
    try {
      await _doc.set({
        SettingsFields.scheduleStartHour: startHour,
        SettingsFields.scheduleEndHour: endHour,
        SettingsFields.updatedAt: FieldValue.serverTimestamp(),
        SettingsFields.updatedBy: FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));
    } catch (e) {
      throw AppException('Jadval vaqtini yangilab bo\'lmadi: $e');
    }
  }

  @override
  Future<SmsBalance> getSmsBalance() async {
    try {
      final callable = _functions.httpsCallable('getSmsBalance');
      final result = await callable.call<Map<String, dynamic>>();
      final data = result.data;
      final statistics = Map<String, dynamic>.from(data['statistics'] as Map? ?? const {});
      return SmsBalance(
        balance: (data['balance'] as num?)?.toInt() ?? 0,
        smsPrice: (data['smsPrice'] as num?)?.toInt() ?? 0,
        totalSms: (statistics['totalSms'] as num?)?.toInt() ?? 0,
        totalSpent: (statistics['totalSpent'] as num?)?.toInt() ?? 0,
        todaySms: (statistics['todaySms'] as num?)?.toInt() ?? 0,
        todaySpent: (statistics['todaySpent'] as num?)?.toInt() ?? 0,
        monthSms: (statistics['monthSms'] as num?)?.toInt() ?? 0,
        monthSpent: (statistics['monthSpent'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'SMS balansini yuklab bo\'lmadi.');
    } catch (e) {
      throw AppException('SMS balansini yuklab bo\'lmadi: $e');
    }
  }
}
