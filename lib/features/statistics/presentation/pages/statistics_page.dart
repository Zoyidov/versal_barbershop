import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/statistics_cubit.dart';
import '../widgets/client_stat_card.dart';
import 'client_detail_page.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StatisticsCubit>(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Statistika',
                    style: AppTextStyles.displayLarge,
                    textScaler: const TextScaler.linear(0.85),
                  ),
                ),
              ),
              Expanded(
                child: BlocBuilder<StatisticsCubit, StatisticsState>(
                  builder: (context, state) {
                    if (state.status == StatisticsStatus.loading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                    }
                    if (state.clients.isEmpty) {
                      return Center(
                        child: Text('Hali mijozlar tarixi yo\'q', style: AppTextStyles.bodyMuted),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: state.clients.length,
                      itemBuilder: (context, index) {
                        final client = state.clients[index];
                        return ClientStatCard(
                          stat: client,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ClientDetailPage(client: client)),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
