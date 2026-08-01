import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_colors.dart';
import 'core/widgets/custom_bottom_nav_bar.dart';
import 'core/widgets/gradient_background.dart';
import 'features/admin/presentation/cubit/pending_approval_cubit.dart';
import 'features/appointments/presentation/pages/dashboard_page.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/statistics/presentation/pages/client_search_page.dart';
import 'features/statistics/presentation/pages/statistics_page.dart';

/// Authenticated app shell: three tabs behind the static bottom nav bar.
///
/// Uses an [IndexedStack] rather than swapping widgets so each tab keeps
/// its own scroll position and Firestore stream subscriptions alive
/// across switches, and so nothing in the tab body re-animates in either
/// — consistent with the "nav bar must stay static" requirement covering
/// the whole tab-switch interaction, not just the bar's icons.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  static const _items = [
    BottomNavItemData(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Bosh sahifa'),
    BottomNavItemData(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Statistika'),
    BottomNavItemData(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Sozlamalar'),
  ];
  static const _settingsTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<PendingApprovalCubit>().state;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: GradientBackground(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _index,
        items: _items,
        badgeCounts: {_settingsTabIndex: pendingCount},
        onTap: (index) => setState(() => _index = index),
        onSearchTap: () {
          final barber = context.read<AuthCubit>().state.barber;
          final searchBarberId = barber?.isAdmin == true ? null : barber?.uid;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ClientSearchPage(barberId: searchBarberId)),
          );
        },
      ),
    );
  }
}
