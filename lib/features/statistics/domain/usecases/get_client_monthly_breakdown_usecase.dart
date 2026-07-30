import '../entities/monthly_stat.dart';
import '../repositories/statistics_repository.dart';

class GetClientMonthlyBreakdownUseCase {
  final StatisticsRepository _repository;

  GetClientMonthlyBreakdownUseCase(this._repository);

  Future<List<MonthlyStat>> call(String phoneNumber, {String? barberId}) =>
      _repository.getClientMonthlyBreakdown(phoneNumber, barberId: barberId);
}
