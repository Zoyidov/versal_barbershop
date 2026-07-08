import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/public_booking_cubit.dart';

/// Bottom sheet opened from a free slot on [PublicSlotGrid]: collects the
/// client's name/phone and submits `PublicBookingCubit.book`. Shows its own
/// success view in place rather than popping straight back to the grid, so
/// the client gets clear confirmation before dismissing.
class BookingFormSheet extends StatefulWidget {
  final DateTime day;
  final int hour;

  const BookingFormSheet({super.key, required this.day, required this.hour});

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _nameError;
  String? _phoneError;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController(text: UzPhoneInputFormatter.initialText);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final normalizedPhone = Validators.normalizePhone(_phoneController.text);
    setState(() {
      _nameError = name.isEmpty ? 'Ismingizni kiriting' : null;
      _phoneError = normalizedPhone == null ? 'Telefon raqamini to\'g\'ri kiriting' : null;
    });
    if (_nameError != null || _phoneError != null) return;

    final ok = await context
        .read<PublicBookingCubit>()
        .book(hour: widget.hour, name: name, phone: normalizedPhone!);
    if (!mounted || !ok) return;
    setState(() => _success = true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_success) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 32, 20, bottomInset + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
            const SizedBox(height: 16),
            Text('Band qilindi!', style: AppTextStyles.headline.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              '${DateFormatter.fullDate(widget.day)}, ${widget.hour.toString().padLeft(2, '0')}:00 da kutamiz.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(label: 'Yopish', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: BlocBuilder<PublicBookingCubit, PublicBookingState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGlassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Band qilish', style: AppTextStyles.headline.copyWith(fontSize: 19)),
              const SizedBox(height: 4),
              Text(
                '${DateFormatter.fullDate(widget.day)}, ${widget.hour.toString().padLeft(2, '0')}:00',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _nameController,
                label: 'Ismingiz',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
              ),
              if (_nameError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(_nameError!, style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phoneController,
                label: 'Telefon raqamingiz',
                keyboardType: TextInputType.phone,
                inputFormatters: [UzPhoneInputFormatter()],
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
              ),
              if (_phoneError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(_phoneError!, style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Joyni band qilish',
                loading: state.isSubmitting,
                onPressed: state.isSubmitting ? null : _submit,
              ),
            ],
          );
        },
      ),
    );
  }
}
