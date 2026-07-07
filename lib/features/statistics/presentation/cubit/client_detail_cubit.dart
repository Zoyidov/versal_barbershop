import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/monthly_stat.dart';
import '../../domain/usecases/get_client_monthly_breakdown_usecase.dart';

part 'client_detail_state.dart';

class ClientDetailCubit extends Cubit<ClientDetailState> {
  final GetClientMonthlyBreakdownUseCase _getClientMonthlyBreakdownUseCase;

  ClientDetailCubit({required GetClientMonthlyBreakdownUseCase getClientMonthlyBreakdownUseCase})
      : _getClientMonthlyBreakdownUseCase = getClientMonthlyBreakdownUseCase,
        super(const ClientDetailState());

  Future<void> load(String phoneNumber) async {
    emit(state.copyWith(status: ClientDetailStatus.loading));
    try {
      final stats = await _getClientMonthlyBreakdownUseCase(phoneNumber);
      emit(state.copyWith(status: ClientDetailStatus.loaded, monthlyStats: stats));
    } on AppException catch (e) {
      emit(state.copyWith(status: ClientDetailStatus.error, errorMessage: e.message));
    }
  }
}
