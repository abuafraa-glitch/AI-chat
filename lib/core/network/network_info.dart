import 'package:connectivity_plus/connectivity_plus.dart';

/// Contract for querying device network connectivity.
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectivityStream;
}

/// Production implementation backed only by connectivity_plus.
///
/// This deliberately avoids a second reachability SDK during app startup.
/// A network interface indicates that the app may attempt its backend request;
/// the HTTP layer remains responsible for handling timeouts and failures.
final class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl({required Connectivity connectivity})
      : _connectivity = connectivity;

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      return _hasNetworkInterface(results);
    } catch (_) {
      // Connectivity is advisory only. A plugin/platform failure must not
      // crash startup or prevent the HTTP layer from reporting its own error.
      return false;
    }
  }

  @override
  Stream<bool> get connectivityStream async* {
    try {
      await for (final results in _connectivity.onConnectivityChanged) {
        yield _hasNetworkInterface(results);
      }
    } catch (_) {
      // Stop monitoring safely if Android's connectivity provider fails.
      yield false;
    }
  }

  static bool _hasNetworkInterface(List<ConnectivityResult> results) =>
      results.any(
        (result) =>
            result != ConnectivityResult.none &&
            result != ConnectivityResult.bluetooth,
      );
}
