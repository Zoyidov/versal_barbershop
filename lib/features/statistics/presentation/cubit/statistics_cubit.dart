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

  /// Which barber's clients this cubit shows. A regular barber is always
  /// pinned to their own uid so their client list never mixes with another
  /// barber's; only an admin caller may pass null ("every barber") or
  /// switch via [setBarberId] (a picker on the Statistics screen).
  String? _barberId;

  StatisticsCubit({
    required WatchClientStatsUseCase watchClientStatsUseCase,
    String? barberId,
  }) : _watchClientStatsUseCase = watchClientStatsUseCase,
       _barberId = barberId,
       super(const StatisticsState()) {
    _subscribe();
  }

  void setBarberId(String? barberId) {
    if (_barberId == barberId) return;
    _barberId = barberId;
    emit(state.copyWith(status: StatisticsStatus.loading));
    _subscribe();
  }

  /// Re-subscribes and waits for the next snapshot, for pull-to-refresh.
  /// The data is already real-time (Firestore pushes updates on its own),
  /// so this exists to give the gesture a concrete round-trip to await and
  /// a moment of visible feedback rather than resolving instantly.
  Future<void> refresh() {
    final completer = Completer<void>();
    _subscribe(completer: completer);
    return completer.future;
  }

  void _subscribe({Completer<void>? completer}) {
    _subscription?.cancel();
    _subscription = _watchClientStatsUseCase(barberId: _barberId).listen(
      (clients) {
        emit(state.copyWith(status: StatisticsStatus.loaded, clients: clients));
        if (completer != null && !completer.isCompleted) completer.complete();
      },
      onError: (error) {
        final message = error is AppException
            ? error.message
            : 'Statistikani yuklab bo\'lmadi.';
        emit(
          state.copyWith(status: StatisticsStatus.error, errorMessage: message),
        );
        if (completer != null && !completer.isCompleted) completer.complete();
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
