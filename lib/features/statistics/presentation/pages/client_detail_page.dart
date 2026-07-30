import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../domain/entities/client_stat.dart';
import '../cubit/client_detail_cubit.dart';
import '../widgets/monthly_bar_row.dart';
import '../widgets/visit_history_row.dart';

class ClientDetailPage extends StatelessWidget {
  final ClientStat client;

  /// Same barber scope the list this client was tapped from used, so the
  /// detail screen never leaks another barber's history for this phone
  /// number into a regular barber's view.
  final String? barberId;

  const ClientDetailPage({super.key, required this.client, this.barberId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClientDetailCubit>()..load(client.phoneNumber, barberId: barberId),
      child: Scaffold(
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          client.lastName?.trim().isNotEmpty == true ? client.lastName! : client.phoneNumber,
                          style: AppTextStyles.headline.copyWith(fontSize: 19),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _LifetimeStat(label: 'Umumiy tashriflar', value: client.totalVisits, color: AppColors.success)),
                      const SizedBox(width: 12),
                      Expanded(child: _LifetimeStat(label: 'Umumiy bekor qilishlar', value: client.totalCancellations, color: AppColors.danger)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BlocBuilder<ClientDetailCubit, ClientDetailState>(
                    builder: (context, state) {
                      if (state.status == ClientDetailStatus.loading) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: 4,
                          itemBuilder: (_, __) => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: ShimmerBlock(height: 76, borderRadius: BorderRadius.all(Radius.circular(18))),
                          ),
                        );
                      }
                      if (state.monthlyStats.isEmpty && state.visits.isEmpty) {
                        return Center(
                          child: Text('Hali tashriflar tarixi yo\'q', style: AppTextStyles.bodyMuted),
                        );
                      }
                      final maxValue = state.monthlyStats
                          .map((s) => s.visits > s.cancellations ? s.visits : s.cancellations)
                          .fold(0, (a, b) => a > b ? a : b);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          if (state.visits.isNotEmpty) ...[
                            Text('Tashriflar tarixi', style: AppTextStyles.title),
                            const SizedBox(height: 12),
                            for (final visit in state.visits) VisitHistoryRow(visit: visit),
                            const SizedBox(height: 8),
                          ],
                          if (state.monthlyStats.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Oylik statistika', style: AppTextStyles.title),
                            const SizedBox(height: 12),
                            for (final stat in state.monthlyStats)
                              MonthlyBarRow(stat: stat, maxValue: maxValue),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LifetimeStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _LifetimeStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: AppTextStyles.displayLarge.copyWith(fontSize: 26, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
