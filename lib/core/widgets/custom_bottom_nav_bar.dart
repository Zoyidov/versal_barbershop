import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BottomNavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Custom glassmorphic bottom navigation bar.
///
/// IMPORTANT (explicit product requirement): items must stay perfectly
/// static when switching tabs — no scale/bounce/translate animation on
/// the icon or label. The only thing that changes on selection is color
/// and a static underline dot; nothing moves or resizes. Do not add
/// AnimatedScale/AnimatedContainer-driven bounce here.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItemData> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: AppColors.surface.withValues(alpha: 0.72),
                border: Border.all(color: AppColors.surfaceGlassBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final selected = index == currentIndex;
                  final item = items[index];
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTap(index),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: SizedBox.expand(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // No AnimatedContainer / AnimatedScale / bounce
                            // curves on purpose: icon and label sizes are
                            // fixed constants regardless of `selected`.
                            children: [
                              Icon(
                                selected ? item.activeIcon : item.icon,
                                size: 24,
                                color: selected
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: AppTextStyles.caption.copyWith(
                                  color: selected
                                      ? AppColors.gold
                                      : AppColors.textMuted,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected
                                      ? AppColors.gold
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
