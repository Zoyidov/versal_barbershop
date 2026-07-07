part of 'statistics_cubit.dart';

enum StatisticsStatus { loading, loaded, error }

class StatisticsState extends Equatable {
  final StatisticsStatus status;
  final List<ClientStat> clients;
  final String? errorMessage;

  const StatisticsState({
    this.status = StatisticsStatus.loading,
    this.clients = const [],
    this.errorMessage,
  });

  StatisticsState copyWith({
    StatisticsStatus? status,
    List<ClientStat>? clients,
    String? errorMessage,
  }) {
    return StatisticsState(
      status: status ?? this.status,
      clients: clients ?? this.clients,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, clients, errorMessage];
}
