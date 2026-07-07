import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/client_stat.dart';
import '../../domain/usecases/search_clients_usecase.dart';

part 'client_search_state.dart';

/// Debounced client search backing the nav bar's search capsule: as the
/// barber types, waits briefly for typing to settle before hitting
/// Firestore, so every keystroke doesn't fire its own query.
class ClientSearchCubit extends Cubit<ClientSearchState> {
  final SearchClientsUseCase _searchClientsUseCase;
  Timer? _debounce;

  ClientSearchCubit({required SearchClientsUseCase searchClientsUseCase})
      : _searchClientsUseCase = searchClientsUseCase,
        super(const ClientSearchState());

  void onQueryChanged(String query) {
    emit(state.copyWith(query: query, clearError: true));
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      emit(state.copyWith(status: ClientSearchStatus.idle, results: []));
      return;
    }

    emit(state.copyWith(status: ClientSearchStatus.loading));
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await _searchClientsUseCase(query);
      if (isClosed || state.query != query) return;
      emit(state.copyWith(status: ClientSearchStatus.loaded, results: results));
    } on AppException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: ClientSearchStatus.error, errorMessage: e.message));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
