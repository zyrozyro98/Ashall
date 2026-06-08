import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/utils/security_utils.dart';

void main() {
  group('SecurityUtils Tests', () {
    test('generateVerificationCode generates a 4-digit code', () {
      final code = SecurityUtils.generateVerificationCode();
      expect(code.length, 4);
      expect(int.tryParse(code), isNotNull);
      expect(int.parse(code) >= 1000 && int.parse(code) <= 9999, isTrue);
    });

    test('generateVerificationCode generates random codes', () {
      final code1 = SecurityUtils.generateVerificationCode();
      // While there is a 1/9000 chance they are the same, it is highly likely they are different
      // Run multiple tests if we want to be absolutely sure, but for basic tests this is okay.
      // If code1 == code2 we can just log a warning or do another generation.
      bool isRandom = false;
      for (int i = 0; i < 10; i++) {
        if (SecurityUtils.generateVerificationCode() != code1) {
          isRandom = true;
          break;
        }
      }
      expect(isRandom, isTrue);
    });

    test('verifyCode returns true for exact matches', () {
      expect(SecurityUtils.verifyCode('1234', '1234'), isTrue);
      expect(SecurityUtils.verifyCode('9999', '9999'), isTrue);
    });

    test('verifyCode returns false for non-matching codes', () {
      expect(SecurityUtils.verifyCode('1234', '4321'), isFalse);
      expect(SecurityUtils.verifyCode('1234', '1235'), isFalse);
    });

    test('verifyCode returns false for invalid lengths', () {
      expect(SecurityUtils.verifyCode('123', '123'), isFalse);
      expect(SecurityUtils.verifyCode('12345', '12345'), isFalse);
      expect(SecurityUtils.verifyCode('1234', '123'), isFalse);
    });

    test('verifyCode ignores trailing and leading whitespace', () {
      expect(SecurityUtils.verifyCode('1234', ' 1234 '), isTrue);
    });

    test('verifyCode handles nulls gracefully', () {
      expect(SecurityUtils.verifyCode(null, '1234'), isFalse);
      expect(SecurityUtils.verifyCode('1234', null), isFalse);
      expect(SecurityUtils.verifyCode(null, null), isFalse);
    });
  });
}
