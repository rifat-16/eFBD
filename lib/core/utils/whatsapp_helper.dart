class WhatsappHelper {
  /// Formats a raw phone number into standard international format with `+` prefix.
  /// Automatically converts Bangladeshi numbers like `01601734167` -> `+8801601734167`.
  static String formatNumber(String rawNumber) {
    if (rawNumber.trim().isEmpty) return '';

    String cleaned = rawNumber.trim();
    bool hasPlus = cleaned.startsWith('+');
    String digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) return rawNumber;

    // If already starts with 880 (13 digits)
    if (digitsOnly.startsWith('880') && digitsOnly.length == 13) {
      return '+$digitsOnly';
    }

    // If starts with 01 (11 digits, standard BD mobile number)
    if (digitsOnly.startsWith('01') && digitsOnly.length == 11) {
      return '+88$digitsOnly';
    }

    // If starts with 1 (10 digits, missing 0 and country code)
    if (digitsOnly.startsWith('1') && digitsOnly.length == 10) {
      return '+880$digitsOnly';
    }

    // If original string had '+', preserve '+' with digits
    if (hasPlus) {
      return '+$digitsOnly';
    }

    return '+$digitsOnly';
  }

  /// Returns digits-only suitable for wa.me/ links (e.g. `8801601734167`).
  static String digitsForUrl(String rawNumber) {
    final formatted = formatNumber(rawNumber);
    return formatted.replaceAll(RegExp(r'\D'), '');
  }
}
