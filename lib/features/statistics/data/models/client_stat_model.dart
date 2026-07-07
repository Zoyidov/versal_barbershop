import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/client_stat.dart';

class ClientStatModel extends ClientStat {
  const ClientStatModel({
    required super.phoneNumber,
    super.lastName,
    required super.totalVisits,
    required super.totalCancellations,
  });

  factory ClientStatModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data() ?? const {};
    return ClientStatModel(
      phoneNumber: json[ClientFields.phoneNumber] as String? ?? doc.id,
      lastName: json[ClientFields.lastName] as String?,
      totalVisits: (json[ClientFields.totalVisits] as num?)?.toInt() ?? 0,
      totalCancellations: (json[ClientFields.totalCancellations] as num?)?.toInt() ?? 0,
    );
  }
}
