import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AppHourField extends StatelessWidget {
  const AppHourField({
    super.key,
    required this.label,
    required this.value, // tanlangan soat (0-23), null bo'lishi mumkin
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    int tempValue = value ?? 0;

    await showCupertinoModalPopup(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return _HourPickerSheet(
          initialValue: tempValue,
          onConfirm: (val) => onChanged(val),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMuted,
          filled: true,
          fillColor: AppColors.surface,
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.25)),
          ),
        ),
        child: Text(
          value != null ? '${value.toString().padLeft(2, '0')}:00' : 'Tanlang',
          style: AppTextStyles.title.copyWith(
            fontSize: 16,
            color: value != null ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _HourPickerSheet extends StatefulWidget {
  const _HourPickerSheet({
    required this.initialValue,
    required this.onConfirm,
  });

  final int initialValue;
  final ValueChanged<int> onConfirm;

  @override
  State<_HourPickerSheet> createState() => _HourPickerSheetState();
}

class _HourPickerSheetState extends State<_HourPickerSheet> {
  late int _tempValue = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Tepadagi tortish tutqichi (drag handle)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              // Sarlavha qatori — endi tabiiy balandlikda, kesilib qolmaydi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Bekor qilish',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 15),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      onPressed: () {
                        widget.onConfirm(_tempValue);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Tayyor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.textMuted.withOpacity(0.2),
              ),
              // Soat g'ildiragi
              SizedBox(
                height: 220,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: AppTextStyles.title.copyWith(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  child: CupertinoPicker(
                    itemExtent: 44,
                    backgroundColor: Colors.transparent,
                    scrollController: FixedExtentScrollController(
                      initialItem: widget.initialValue,
                    ),
                    selectionOverlay: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() => _tempValue = index);
                    },
                    children: List.generate(24, (index) {
                      return Center(
                        child: Text(
                          '${index.toString().padLeft(2, '0')}:00',
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}