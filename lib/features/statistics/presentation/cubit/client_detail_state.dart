part of 'client_detail_cubit.dart';

enum ClientDetailStatus { loading, loaded, error }

class ClientDetailState extends Equatable {
  final ClientDetailStatus status;
  final List<MonthlyStat> monthlyStats;
  final String? errorMessage;

  const ClientDetailState({
    this.status = ClientDetailStatus.loading,
    this.monthlyStats = const [],
    this.errorMessage,
  });

  ClientDetailState copyWith({
    ClientDetailStatus? status,
    List<MonthlyStat>? monthlyStats,
    String? errorMessage,
  }) {
    return ClientDetailState(
      status: status ?? this.status,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, monthlyStats, errorMessage];
}
