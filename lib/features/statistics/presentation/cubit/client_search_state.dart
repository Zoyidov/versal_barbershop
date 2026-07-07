part of 'client_search_cubit.dart';

enum ClientSearchStatus { idle, loading, loaded, error }

class ClientSearchState extends Equatable {
  final ClientSearchStatus status;
  final String query;
  final List<ClientStat> results;
  final String? errorMessage;

  const ClientSearchState({
    this.status = ClientSearchStatus.idle,
    this.query = '',
    this.results = const [],
    this.errorMessage,
  });

  ClientSearchState copyWith({
    ClientSearchStatus? status,
    String? query,
    List<ClientStat>? results,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ClientSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, query, results, errorMessage];
}
