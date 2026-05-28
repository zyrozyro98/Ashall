class PhoneUtils {
  /// Normalizes phone number to digits only, prepending 967 if necessary, and removing leading 0s.
  static String normalizePhone(String input) {
    // Remove all non-digits
    String digits = input.replaceAll(RegExp(r'\D'), '');
    
    // If it starts with 00967, remove the 00 prefix -> 967...
    if (digits.startsWith('00967')) {
      digits = digits.substring(2);
    }
    
    // If it starts with 0 and is followed by 9 digits (local Yemeni number e.g. 0777123456), remove 0 and add 967 -> 967777123456
    if (digits.startsWith('0') && digits.length == 10) {
      digits = '967${digits.substring(1)}';
    }
    
    // If it doesn't start with 967 and has 9 digits (local Yemeni number e.g. 777123456), add 967 -> 967777123456
    if (!digits.startsWith('967') && digits.length == 9) {
      digits = '967$digits';
    }
    
    return digits;
  }

  /// Formats the phone number visually for display (e.g. +967 777 123 456)
  static String formatForDisplay(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('967') && clean.length == 12) {
      return '+967 ${clean.substring(3, 6)} ${clean.substring(6, 9)} ${clean.substring(9)}';
    }
    if (clean.length == 9) {
      return '+967 ${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6)}';
    }
    if (phone.isEmpty) return '';
    return phone.startsWith('+') ? phone : '+$phone';
  }

  /// Checks if the phone number is valid (Yemeni phone number: 9 digits after country code 967)
  static bool isValidPhone(String phone) {
    String normalized = normalizePhone(phone);
    // Yemeni mobile numbers have country code 967 + 9 digits starting with 77, 73, 71, 70
    // Total length = 12 digits
    return normalized.length == 12 && 
           normalized.startsWith('967') && 
           (normalized[3] == '7');
  }
}
