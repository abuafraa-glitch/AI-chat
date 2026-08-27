import 'package:ai_chat/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('secure storage service can be constructed with current options', () {
    const storage = FlutterSecureStorage(aOptions: AndroidOptions());
    final service = SecureStorageService(storage: storage);

    expect(service, isA<SecureStorageService>());
  });
}

// This test intentionally avoids the removed encryptedSharedPreferences
// getter. The production service uses const AndroidOptions(), which is the
// supported configuration in the installed flutter_secure_storage version.
