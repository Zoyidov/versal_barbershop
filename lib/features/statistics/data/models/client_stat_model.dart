import '../../domain/entities/client_stat.dart';

class ClientStatModel extends ClientStat {
  const ClientStatModel({
    required super.phoneNumber,
    super.lastName,
    required super.totalVisits,
    required super.totalCancellations,
  });
}
