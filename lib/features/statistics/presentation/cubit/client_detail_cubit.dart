import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/client_visit.dart';
import '../../domain/entities/monthly_stat.dart';
import '../../domain/usecases/get_client_monthly_breakdown_usecase.dart';
import '../../domain/usecases/get_client_visits_usecase.dart';

part 'client_detail_state.dart';

class ClientDetailCubit extends Cubit<ClientDetailState> {
  final GetClientMonthlyBreakdownUseCase _getClientMonthlyBreakdownUseCase;
  final GetClientVisitsUseCase _getClientVisitsUseCase;

  ClientDetailCubit({
    required GetClientMonthlyBreakdownUseCase getClientMonthlyBreakdownUseCase,
    required GetClientVisitsUseCase getClientVisitsUseCase,
  })  : _getClientMonthlyBreakdownUseCase = getClientMonthlyBreakdownUseCase,
        _getClientVisitsUseCase = getClientVisitsUseCase,
        super(const ClientDetailState());

  Future<void> load(String phoneNumber, {String? barberId}) async {
    emit(state.copyWith(status: ClientDetailStatus.loading));
    try {
      final results = await Future.wait([
        _getClientMonthlyBreakdownUseCase(phoneNumber, barberId: barberId),
        _getClientVisitsUseCase(phoneNumber, barberId: barberId),
      ]);
      emit(state.copyWith(
        status: ClientDetailStatus.loaded,
        monthlyStats: results[0] as List<MonthlyStat>,
        visits: results[1] as List<ClientVisit>,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(status: ClientDetailStatus.error, errorMessage: e.message));
    }
  }
}
