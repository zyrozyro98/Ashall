import 'dart:math';

class SecurityUtils {
  /// Generates a random 4-digit code (from 1000 to 9999) as a String.
  static String generateVerificationCode() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  /// Verifies if the provided code matches the expected code.
  /// Also ensures the code is exactly 4 digits.
  static bool verifyCode(String? expectedCode, String? providedCode) {
    if (expectedCode == null || expectedCode.isEmpty) return false;
    if (providedCode == null || providedCode.isEmpty) return false;
    if (expectedCode.length != 4 || providedCode.length != 4) return false;
    return expectedCode == providedCode.trim();
  }
}
