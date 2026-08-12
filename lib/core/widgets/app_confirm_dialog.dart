import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Glass-styled confirmation dialog matching the app's "liquid glass" look,
/// used for destructive confirmations (e.g. cancelling an appointment)
/// instead of the stock [AlertDialog].
class AppConfirmDialog {
  AppConfirmDialog._();

  /// Shows the dialog and returns true only if the user tapped [confirmLabel].
  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Orqaga',
    Color accentColor = AppColors.danger,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => _AppConfirmDialogView(
        icon: icon,
        title: title,
        message: message,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        accentColor: accentColor,
      ),
    );
    return confirmed ?? false;
  }
}

class _AppConfirmDialogView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final Color accentColor;

  const _AppConfirmDialogView({
    required this.icon,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withValues(alpha: 0.9),
                  AppColors.surface.withValues(alpha: 0.98),
                ],
              ),
              border: Border.all(color: AppColors.surfaceGlassBorder, width: 1.1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.14),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(height: 18),
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(message, style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: cancelLabel,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        label: confirmLabel,
                        color: accentColor,
                        filled: true,
                        onTap: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool filled;

  const _DialogButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: filled ? color.withValues(alpha: 0.16) : Colors.transparent,
            border: Border.all(color: filled ? color.withValues(alpha: 0.6) : AppColors.surfaceGlassBorder),
          ),
          child: Text(
            label,
            style: AppTextStyles.title.copyWith(fontSize: 14.5, color: filled ? color : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
