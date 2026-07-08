import '../entities/sms_balance.dart';
import '../repositories/settings_repository.dart';

class GetSmsBalanceUseCase {
  final SettingsRepository _repository;

  GetSmsBalanceUseCase(this._repository);

  Future<SmsBalance> call() => _repository.getSmsBalance();
}
