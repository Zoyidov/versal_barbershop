import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../models/managed_user_model.dart';

abstract class AdminRemoteDataSource {
  /// Streams every `users` doc. Only readable by an admin (see
  /// firestore.rules `isAdmin()`), so this throws a permission error for
  /// anyone else - callers must gate this screen behind `barber.isAdmin`.
  Stream<List<ManagedUserModel>> watchUsers();

  Future<void> approveBarber({required String uid, required int smsLimit});
  Future<void> setSmsLimit({required String uid, required int smsLimit});
  Future<void> setUserActive({required String uid, required bool active});

  /// Writes straight to Firestore rather than through a callable - unlike
  /// the fields above, firestore.rules lets an admin update a barber's
  /// `scheduleStartHour`/`scheduleEndHour` directly (see `match /users/{uid}`).
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour});
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AdminRemoteDataSourceImpl({required FirebaseFirestore firestore, required FirebaseFunctions functions})
      : _firestore = firestore,
        _functions = functions;

  @override
  Stream<List<ManagedUserModel>> watchUsers() {
    return _firestore.collection(FirestorePaths.users).snapshots().map(
          (snapshot) => snapshot.docs.map(ManagedUserModel.fromSnapshot).toList(),
        );
  }

  @override
  Future<void> approveBarber({required String uid, required int smsLimit}) async {
    try {
      await _functions.httpsCallable('approveBarber').call<Map<String, dynamic>>({
        'uid': uid,
        'smsLimit': smsLimit,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'Tasdiqlashda xatolik yuz berdi.');
    }
  }

  @override
  Future<void> setSmsLimit({required String uid, required int smsLimit}) async {
    try {
      await _functions.httpsCallable('setSmsLimit').call<Map<String, dynamic>>({
        'uid': uid,
        'smsLimit': smsLimit,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'SMS limitini o\'zgartirishda xatolik yuz berdi.');
    }
  }

  @override
  Future<void> setUserActive({required String uid, required bool active}) async {
    try {
      await _functions.httpsCallable('setUserActive').call<Map<String, dynamic>>({
        'uid': uid,
        'active': active,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'Holatni o\'zgartirishda xatolik yuz berdi.');
    }
  }

  @override
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour}) async {
    try {
      await _firestore.collection(FirestorePaths.users).doc(uid).update({
        UserFields.scheduleStartHour: startHour,
        UserFields.scheduleEndHour: endHour,
      });
    } catch (e) {
      throw AppException('Ish vaqtini yangilab bo\'lmadi: $e');
    }
  }
}
