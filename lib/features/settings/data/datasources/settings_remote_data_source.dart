import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../models/app_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Stream<AppSettingsModel> watchSettings();
  Future<void> updateReminderWindow(int minutes);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDataSourceImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

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
}
