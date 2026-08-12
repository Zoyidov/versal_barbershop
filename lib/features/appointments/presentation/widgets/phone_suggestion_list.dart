import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../statistics/domain/entities/client_stat.dart';

/// Tap-to-fill list of existing clients whose phone (or name) matches what's
/// been typed into the phone field so far, shown above it while the barber
/// is still typing so a returning client doesn't need to be typed in full.
class PhoneSuggestionList extends StatelessWidget {
  final List<ClientStat> suggestions;
  final ValueChanged<ClientStat> onSelected;

  const PhoneSuggestionList({super.key, required this.suggestions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGradientStart,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceGlassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < suggestions.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.surfaceGlassBorder),
            _SuggestionTile(client: suggestions[i], onTap: () => onSelected(suggestions[i])),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final ClientStat client;
  final VoidCallback onTap;

  const _SuggestionTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = client.lastName?.trim();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.gold, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    UzPhoneInputFormatter.formatDisplay(client.phoneNumber),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (name != null && name.isNotEmpty)
                    Text(name, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.north_west_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}
