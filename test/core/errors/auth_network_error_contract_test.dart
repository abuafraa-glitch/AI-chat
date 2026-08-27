import 'package:ai_chat/core/errors/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline authentication failures carry an offline marker', () {
    const error = NetworkException(
      message: 'No connection',
      metadata: <String, dynamic>{'offline': true},
    );

    expect(error.metadata?['offline'], isTrue);
    expect(error.code, 'ERR_NO_CONNECTION');
  });

  test('gateway failures preserve the HTTP status for UI classification', () {
    const error = ServerException(
      message: 'Bad gateway',
      metadata: <String, dynamic>{'statusCode': 502},
    );

    expect(error.metadata?['statusCode'], 502);
    expect(error.code, 'ERR_SERVER');
  });
}
