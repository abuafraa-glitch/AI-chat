import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Describes the current network interface posture of the device.
enum ConnectivityStatus { connected, noInternet, disconnected }

/// Monitors network interfaces without performing a blocking startup probe.
///
/// The backend request remains the source of truth for actual reachability;
/// HTTP timeouts and errors are handled by the network layer.
final class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  ConnectivityStatus _status = ConnectivityStatus.disconnected;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityStatus get status => _status;
  Stream<ConnectivityStatus> get statusStream => _controller.stream;
  bool get isConnected => _status == ConnectivityStatus.connected;
  bool get isOffline => !isConnected;

  Future<void> initialise() async {
    // connectivity_plus uses NetworkManager on Linux. Some headless or
    // minimal Linux environments do not provide that D-Bus service; skip the
    // advisory plugin there so it can never abort application startup.
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _emit(ConnectivityStatus.disconnected);
      return;
    }
    try {
      final results = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      _emit(_statusFor(results));
    } catch (_) {
      // Connectivity is advisory only; never block or abort app startup.
      _emit(ConnectivityStatus.disconnected);
    }
    try {
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) => _emit(_statusFor(results)),
        onError: (_) {},
      );
    } catch (_) {
      // The stream is optional and must not prevent the first frame.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  static ConnectivityStatus _statusFor(List<ConnectivityResult> results) {
    final hasInterface = results.any(
      (result) =>
          result != ConnectivityResult.none &&
          result != ConnectivityResult.bluetooth,
    );
    return hasInterface
        ? ConnectivityStatus.connected
        : ConnectivityStatus.disconnected;
  }

  void _emit(ConnectivityStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_controller.isClosed) _controller.add(next);
  }
}
