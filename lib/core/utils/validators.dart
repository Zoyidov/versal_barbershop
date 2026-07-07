/// Form-field validators shared across the app.
///
/// Phone numbers are normalized to the `+998XXXXXXXXX` (Uzbekistan, E.164)
/// format everywhere they touch Firestore, so lookups (smart-alert history,
/// client aggregates) always match regardless of how the digits were typed.
class Validators {
  Validators._();

  static final RegExp _uzPhoneDigits = RegExp(r'^\d{9}$');

  /// Normalizes any of `901234567`, `+998901234567`, `998901234567`,
  /// or a value containing spaces/dashes into `+998901234567`.
  /// Returns null if the input can't be normalized to a valid UZ number.
  static String? normalizePhone(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    String nineDigits;
    if (digitsOnly.length == 9) {
      nineDigits = digitsOnly;
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('998')) {
      nineDigits = digitsOnly.substring(3);
    } else {
      return null;
    }
    if (!_uzPhoneDigits.hasMatch(nineDigits)) return null;
    return '+998$nineDigits';
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon raqami kiritilishi shart';
    }
    if (normalizePhone(value) == null) {
      return 'Yaroqli telefon raqamini kiriting (masalan: 90 123 45 67)';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'Bu maydon'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName kiritilishi shart';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Parol kiritilishi shart';
    if (value.length < 6) return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
    return null;
  }

  static String? reminderMinutes(String? value) {
    if (value == null || value.trim().isEmpty) return 'Majburiy';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Butun son kiriting';
    if (parsed < 1 || parsed > 1440) return '1 dan 1440 gacha bo\'lishi kerak';
    return null;
  }
}
