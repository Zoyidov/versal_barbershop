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

/// Compact "Liquid Glass" (iOS 26-style) bottom navigation: a small
/// floating pill for the tabs, plus a separate circular search capsule
/// floating to its right - same visual language, same blur/vibrancy, but
/// its own tappable surface (mirrors the iOS Liquid Glass tab bar /
/// Telegram pattern of splitting search out of the main bar).
///
/// IMPORTANT (explicit product requirement): tab items must stay
/// perfectly static when switching tabs — no scale/bounce/translate
/// animation on the icon or label. The only thing that changes on
/// selection is color; nothing moves or resizes. Do not add
/// AnimatedContainer/AnimatedScale-driven bounce here.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItemData> items;
  final VoidCallback? onSearchTap;

  /// Small count badge per tab index (e.g. pending-approval count on the
  /// Settings tab). A missing or zero entry shows no badge.
  final Map<int, int> badgeCounts;

  static const double _barHeight = 56;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onSearchTap,
    this.badgeCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _GlassPill(height: _barHeight, child: _buildTabs())),
            if (onSearchTap != null) ...[
              const SizedBox(width: 10),
              _GlassPill(
                height: _barHeight,
                width: _barHeight,
                onTap: onSearchTap,
                child: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 22),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(items.length, (index) {
        final selected = index == currentIndex;
        final item = items[index];
        final badgeCount = badgeCounts[index] ?? 0;
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
                  // No AnimatedContainer / AnimatedScale / bounce curves on
                  // purpose: icon and label sizes are fixed constants
                  // regardless of `selected`.
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 20,
                          color: selected ? AppColors.gold : AppColors.textMuted,
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            top: -4,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.surface, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  badgeCount > 9 ? '9+' : '$badgeCount',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9.5,
                        color: selected ? AppColors.gold : AppColors.textMuted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Shared floating glass pill primitive so the tab bar and the search
/// capsule read as one consistent "Liquid Glass" surface at two sizes.
class _GlassPill extends StatelessWidget {
  final double height;
  final double? width;
  final Widget child;
  final VoidCallback? onTap;

  const _GlassPill({required this.height, this.width, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.gold.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: AppColors.surface.withValues(alpha: 0.6),
                border: Border.all(color: AppColors.surfaceGlassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
