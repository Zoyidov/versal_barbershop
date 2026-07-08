part of 'client_detail_cubit.dart';

enum ClientDetailStatus { loading, loaded, error }

class ClientDetailState extends Equatable {
  final ClientDetailStatus status;
  final List<MonthlyStat> monthlyStats;
  final List<ClientVisit> visits;
  final String? errorMessage;

  const ClientDetailState({
    this.status = ClientDetailStatus.loading,
    this.monthlyStats = const [],
    this.visits = const [],
    this.errorMessage,
  });

  ClientDetailState copyWith({
    ClientDetailStatus? status,
    List<MonthlyStat>? monthlyStats,
    List<ClientVisit>? visits,
    String? errorMessage,
  }) {
    return ClientDetailState(
      status: status ?? this.status,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      visits: visits ?? this.visits,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, monthlyStats, visits, errorMessage];
}
