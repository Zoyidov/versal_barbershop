import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/week_calendar_strip.dart';
import '../cubit/public_booking_cubit.dart';
import '../widgets/booking_form_sheet.dart';
import '../widgets/public_slot_grid.dart';

/// Client-facing self-booking screen: no login required, reachable (for
/// now) via the FAB on the barber's dashboard. Shows the same day-by-day
/// hourly schedule the barber sees, minus any other client's details, and
/// lets a walk-in book themselves into an open hour.
class PublicBookingPage extends StatelessWidget {
  const PublicBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PublicBookingCubit>(),
      child: const _PublicBookingView(),
    );
  }
}

class _PublicBookingView extends StatelessWidget {
  const _PublicBookingView();

  void _openBookingForm(BuildContext context, DateTime day, int hour) {
    final cubit = context.read<PublicBookingCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ColoredBox(
            color: AppColors.surface,
            child: MediaQuery.removePadding(
              context: sheetContext,
              removeTop: true,
              child: BookingFormSheet(day: day, hour: hour),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: BlocConsumer<PublicBookingCubit, PublicBookingState>(
            listenWhen: (p, c) => p.errorMessage != c.errorMessage && c.errorMessage != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            },
            builder: (context, state) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
                    child: Center(
                      child: Text('Band qilish', style: AppTextStyles.displayLarge.copyWith(fontSize: 24)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text('Bo\'sh vaqtni tanlang va joyingizni band qiling', style: AppTextStyles.bodyMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBarberPicker(context, state),
                  const SizedBox(height: 8),
                  WeekCalendarStrip(
                    selectedDay: state.selectedDay,
                    onDaySelected: (day) => context.read<PublicBookingCubit>().selectDay(day),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildBody(context, state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarberPicker(BuildContext context, PublicBookingState state) {
    if (state.barbersLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
          ),
        ),
      );
    }
    if (state.barbers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.barbers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final barber = state.barbers[index];
          final selected = barber.uid == state.selectedBarberId;
          return ChoiceChip(
            label: Text(barber.name),
            selected: selected,
            selectedColor: AppColors.gold,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(color: selected ? AppColors.background : AppColors.textPrimary),
            onSelected: (_) {
              if (!selected) context.read<PublicBookingCubit>().selectBarber(barber.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PublicBookingState state) {
    if (state.barbersLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (state.status == PublicBookingStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (state.status == PublicBookingStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 32),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Bo\'sh vaqtlarni yuklab bo\'lmadi.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.read<PublicBookingCubit>().loadSlots(),
                child: const Text('Qayta urinish', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        ),
      );
    }
    if (state.daySlots.slots.isEmpty) {
      return Center(
        child: Text('Bu kun uchun ish jadvali sozlanmagan', style: AppTextStyles.bodyMuted),
      );
    }
    return PublicSlotGrid(
      daySlots: state.daySlots,
      onSlotTap: (hour) => _openBookingForm(context, state.selectedDay, hour),
    );
  }
}
