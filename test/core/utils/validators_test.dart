import 'package:ai_chat/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.required', () {
    test('returns true for non-empty string', () {
      expect(Validators.required('hello'), isTrue);
    });
    test('returns false for null or empty', () {
      expect(Validators.required(null), isFalse);
      expect(Validators.required(''), isFalse);
    });
  });

  group('Validators.email', () {
    test('accepts well-formed emails', () {
      expect(Validators.email('user@example.com'), isTrue);
      expect(Validators.email('a.b+tag@sub.domain.org'), isTrue);
    });
    test('rejects malformed emails and null/empty', () {
      expect(Validators.email(null), isFalse);
      expect(Validators.email(''), isFalse);
      expect(Validators.email('not-an-email'), isFalse);
      expect(Validators.email('missing@tld'), isFalse);
    });
  });

  group('Validators.password', () {
    test('accepts strong passwords', () {
      expect(Validators.password('Abcd1234!'), isTrue);
    });
    test('rejects weak passwords', () {
      expect(Validators.password(null), isFalse);
      expect(Validators.password('weak'), isFalse);
      expect(Validators.password('NoSpecialChar1'), isFalse);
      expect(Validators.password('!@#\$%^&*()noUpperOrDigit'), isFalse);
    });
  });

  group('Validators.username', () {
    test('accepts 3-20 alphanumeric/underscore', () {
      expect(Validators.username('ab_12'), isTrue);
    });
    test('rejects out-of-range or invalid chars', () {
      expect(Validators.username('ab'), isFalse);
      expect(Validators.username('a' * 21), isFalse);
      expect(Validators.username('has space'), isFalse);
    });
  });

  group('Validators.phone', () {
    test('accepts 10-15 digits with optional +', () {
      expect(Validators.phone('+1234567890'), isTrue);
      expect(Validators.phone('123456789012'), isTrue);
    });
    test('rejects letters or too short/long', () {
      expect(Validators.phone('123'), isFalse);
      expect(Validators.phone('1234567890abc'), isFalse);
    });
  });

  group('Validators.numeric/integer/doubleValue', () {
    test('numeric accepts ints, doubles, negatives', () {
      expect(Validators.numeric('42'), isTrue);
      expect(Validators.numeric('-3.14'), isTrue);
      expect(Validators.numeric('abc'), isFalse);
    });
    test('integer rejects doubles', () {
      expect(Validators.integer('42'), isTrue);
      expect(Validators.integer('3.14'), isFalse);
    });
    test('doubleValue accepts doubles', () {
      expect(Validators.doubleValue('3.14'), isTrue);
      expect(Validators.doubleValue('abc'), isFalse);
    });
  });

  group('Validators.fileName/fileSize', () {
    test('fileName rejects path separators and special chars', () {
      expect(Validators.fileName('report.pdf'), isTrue);
      expect(Validators.fileName('bad/name.txt'), isFalse);
      expect(Validators.fileName('col:on.txt'), isFalse);
    });
    test('fileSize enforces maximum', () {
      expect(Validators.fileSize(100, 200), isTrue);
      expect(Validators.fileSize(300, 200), isFalse);
      expect(Validators.fileSize(null, 200), isFalse);
    });
  });

  group('Validators.minLength/maxLength', () {
    test('minLength boundary', () {
      expect(Validators.minLength('abc', 3), isTrue);
      expect(Validators.minLength('ab', 3), isFalse);
      expect(Validators.minLength(null, 1), isFalse);
    });
    test('maxLength boundary', () {
      expect(Validators.maxLength('abc', 3), isTrue);
      expect(Validators.maxLength('abcd', 3), isFalse);
      expect(Validators.maxLength(null, 3), isFalse);
    });
  });
}
