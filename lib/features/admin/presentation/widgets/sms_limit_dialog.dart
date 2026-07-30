import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Prompts for an SMS-credit number, reused for both "approve + set initial
/// limit" and "top up an already-approved barber's limit".
class SmsLimitDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final int initialValue;

  const SmsLimitDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialValue = 0,
  });

  static Future<int?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    int initialValue = 0,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => SmsLimitDialog(title: title, confirmLabel: confirmLabel, initialValue: initialValue),
    );
  }

  @override
  State<SmsLimitDialog> createState() => _SmsLimitDialogState();
}

class _SmsLimitDialogState extends State<SmsLimitDialog> {
  late final _controller = TextEditingController(text: widget.initialValue.toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AppTextField(
              controller: _controller,
              label: 'SMS soni',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Bekor qilish', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: widget.confirmLabel,
                    onPressed: () {
                      final value = int.tryParse(_controller.text.trim()) ?? 0;
                      Navigator.of(context).pop(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
