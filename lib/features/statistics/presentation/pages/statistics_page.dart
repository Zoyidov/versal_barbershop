import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../admin/domain/entities/managed_user.dart';
import '../../../admin/presentation/cubit/user_management_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/client_stat.dart';
import '../cubit/statistics_cubit.dart';
import '../widgets/client_stat_card.dart';
import 'client_detail_page.dart';

/// Each barber only ever sees their own clients here - a fresh
/// [StatisticsCubit] is created scoped to the signed-in barber's own uid.
/// An admin instead gets a barber picker (defaulting to every barber
/// combined), since only admin is meant to see across barbers at all - and
/// the picker includes the admin's own account too, not just approved
/// barbers: every appointment booked before per-barber accounts existed is
/// still attributed to whichever account was later promoted to admin (see
/// `scripts/setAdmin.js`), so that legacy history needs to stay reachable
/// as its own entry rather than only visible lumped into "Hammasi".
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final barber = context.watch<AuthCubit>().state.barber;
    final isAdmin = barber?.isAdmin == true;

    if (isAdmin) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<UserManagementCubit>()),
          BlocProvider(create: (_) => sl<StatisticsCubit>(param1: null)),
        ],
        child: _StatisticsView(
          isAdmin: true,
          adminUid: barber!.uid,
          adminName: barber.name,
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<StatisticsCubit>(param1: barber?.uid),
      child: _StatisticsView(isAdmin: false, barberId: barber?.uid),
    );
  }
}

class _StatisticsView extends StatefulWidget {
  final bool isAdmin;
  final String? barberId;
  final String? adminUid;
  final String? adminName;

  const _StatisticsView({
    required this.isAdmin,
    this.barberId,
    this.adminUid,
    this.adminName,
  });

  @override
  State<_StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<_StatisticsView> {
  String? _selectedBarberId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            if (widget.isAdmin)
              BlocBuilder<UserManagementCubit, UserManagementState>(
                builder: (context, usersState) =>
                    _buildBarberPicker(context, usersState.approvedBarbers),
              ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gold,
                onRefresh: () => context.read<StatisticsCubit>().refresh(),
                child: BlocBuilder<StatisticsCubit, StatisticsState>(
                  builder: (context, state) {
                    if (state.status == StatisticsStatus.loading) {
                      return _buildLoadingList();
                    }
                    if (state.clients.isEmpty) {
                      return _buildEmptyState();
                    }
                    final barberId = widget.isAdmin
                        ? _selectedBarberId
                        : widget.barberId;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      children: [
                        if (widget.isAdmin) ...[
                          _buildSummaryRow(state.clients),
                          const SizedBox(height: 16),
                        ],
                        for (final client in state.clients)
                          ClientStatCard(
                            stat: client,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClientDetailPage(
                                    client: client,
                                    barberId: barberId,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal chip scroller instead of a dropdown - every option is
  /// visible and one tap away, which reads more like the rest of the app's
  /// picker UI (see `PublicBookingPage`'s barber chips) than a form field.
  Widget _buildBarberPicker(BuildContext context, List<ManagedUser> barbers) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: [
          _BarberChip(
            label: 'Hammasi',
            icon: Icons.groups_rounded,
            selected: _selectedBarberId == null,
            onTap: () => _selectBarber(context, null),
          ),
          if (widget.adminUid != null) ...[
            const SizedBox(width: 8),
            _BarberChip(
              label: '${widget.adminName ?? 'Admin'} (men)',
              icon: Icons.star_rounded,
              selected: _selectedBarberId == widget.adminUid,
              onTap: () => _selectBarber(context, widget.adminUid),
            ),
          ],
          for (final b in barbers) ...[
            const SizedBox(width: 8),
            _BarberChip(
              label: b.name,
              icon: Icons.person_rounded,
              selected: _selectedBarberId == b.uid,
              onTap: () => _selectBarber(context, b.uid),
            ),
          ],
        ],
      ),
    );
  }

  void _selectBarber(BuildContext context, String? uid) {
    if (_selectedBarberId == uid) return;
    setState(() => _selectedBarberId = uid);
    context.read<StatisticsCubit>().setBarberId(uid);
  }

  Widget _buildSummaryRow(List<ClientStat> clients) {
    final totalVisits = clients.fold<int>(0, (sum, c) => sum + c.totalVisits);
    final totalCancellations = clients.fold<int>(
      0,
      (sum, c) => sum + c.totalCancellations,
    );
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: 'Mijozlar',
              value: clients.length,
              color: AppColors.gold,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _SummaryStat(
              label: 'Tashriflar',
              value: totalVisits,
              color: AppColors.success,
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _SummaryStat(
              label: 'Bekor qilingan',
              value: totalCancellations,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 32, color: AppColors.surfaceGlassBorder);

  /// A plain centered `Column` has nothing scrollable for `RefreshIndicator`
  /// to attach its overscroll gesture to, so pull-to-refresh silently
  /// wouldn't work here - wrapping it in a `ListView` (forced always-
  /// scrollable, even though the content is short) fixes that.
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        color: AppColors.textMuted,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hali mijozlar tarixi yo\'q',
                        style: AppTextStyles.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: 6,
      itemBuilder: (context, index) => const _ClientStatShimmer(),
    );
  }
}

class _BarberChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _BarberChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: selected
                ? const LinearGradient(colors: AppColors.goldGradient)
                : null,
            color: selected ? null : AppColors.surfaceGlass,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.surfaceGlassBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.title.copyWith(
                  fontSize: 13,
                  color: selected
                      ? AppColors.background
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

class _ClientStatShimmer extends StatelessWidget {
  const _ClientStatShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            const ShimmerBlock(
              height: 44,
              width: 44,
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBlock(height: 13, width: 110),
                  SizedBox(height: 6),
                  ShimmerBlock(height: 11, width: 90),
                ],
              ),
            ),
            const ShimmerBlock(height: 16, width: 24),
            const SizedBox(width: 12),
            const ShimmerBlock(height: 16, width: 24),
          ],
        ),
      ),
    );
  }
}
