import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/client_stat.dart';
import '../../domain/usecases/watch_client_stats_usecase.dart';

part 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  final WatchClientStatsUseCase _watchClientStatsUseCase;
  StreamSubscription<List<ClientStat>>? _subscription;

  StatisticsCubit({required WatchClientStatsUseCase watchClientStatsUseCase})
      : _watchClientStatsUseCase = watchClientStatsUseCase,
        super(const StatisticsState()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription = _watchClientStatsUseCase().listen(
      (clients) => emit(state.copyWith(status: StatisticsStatus.loaded, clients: clients)),
      onError: (error) {
        final message = error is AppException ? error.message : 'Statistikani yuklab bo\'lmadi.';
        emit(state.copyWith(status: StatisticsStatus.error, errorMessage: message));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
