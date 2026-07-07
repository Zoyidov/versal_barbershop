import 'package:flutter/services.dart';

/// Keeps `+998 ` permanently at the start of the field and groups the
/// remaining 9 digits as `## ### ## ##` while typing (e.g. `+998 90 123 45
/// 67`). Digits are re-derived from whatever the user typed/deleted, so
/// there's no way to remove or edit the `+998 ` prefix itself - deleting
/// "through" it just clears the digits after it.
class UzPhoneInputFormatter extends TextInputFormatter {
  static const String prefix = '+998 ';
  static const List<int> _groupSizes = [2, 3, 2, 2];

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998')) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);

    final groups = <String>[];
    var index = 0;
    for (final size in _groupSizes) {
      if (index >= digits.length) break;
      final end = (index + size).clamp(0, digits.length);
      groups.add(digits.substring(index, end));
      index = end;
    }

    final text = groups.isEmpty ? prefix : '$prefix${groups.join(' ')}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Text to seed a controller with so the field always shows the prefix,
  /// even before the barber has typed anything.
  static String get initialText => prefix;

  /// Formats an already-normalized `+998XXXXXXXXX` number (or any string
  /// containing those digits) into the grouped display form, for seeding a
  /// controller when editing an existing appointment/account.
  static String formatDisplay(String phoneNumber) {
    var digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998')) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);

    final groups = <String>[];
    var index = 0;
    for (final size in _groupSizes) {
      if (index >= digits.length) break;
      final end = (index + size).clamp(0, digits.length);
      groups.add(digits.substring(index, end));
      index = end;
    }
    return groups.isEmpty ? prefix : '$prefix${groups.join(' ')}';
  }
}
