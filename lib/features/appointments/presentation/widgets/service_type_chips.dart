import 'package:flutter/material.dart';

import '../../../../core/constants/service_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Optional service-type selector rendered as a wrap of selectable chips,
/// per spec ("optional dropdown/chips selection"). Tapping the already
/// selected chip clears the selection since the field is optional.
class ServiceTypeChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const ServiceTypeChips({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kServiceTypes.map((serviceType) {
        final isSelected = serviceType == selected;
        return GestureDetector(
          onTap: () => onSelected(serviceType),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: isSelected ? AppColors.gold.withValues(alpha: 0.16) : AppColors.surfaceGlass,
              border: Border.all(
                color: isSelected ? AppColors.gold : AppColors.surfaceGlassBorder,
              ),
            ),
            child: Text(
              serviceType,
              style: AppTextStyles.body.copyWith(
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
