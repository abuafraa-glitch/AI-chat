import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Describes the current network reachability posture of the device.
enum ConnectivityStatus {
  /// The device has an active network interface with confirmed internet
  /// access.
  connected,

  /// The device has an active network interface but cannot reach the
  /// public internet (e.g. captive portal, NAT-only, airplane-mode
  /// Wi-Fi).
  noInternet,

  /// The device has no active network interface.
  disconnected,
}

/// Monitors network reachability for the Hajeen AI application.
///
/// [ConnectivityService] combines two independent signals:
///
/// 1. **[Connectivity]** (from `connectivity_plus`) — detects a live
///    network interface (Wi-Fi, mobile, ethernet, VPN, …).
/// 2. **[InternetConnection]** (from `internet_connection_checker_plus`)
///    — verifies that the interface can reach the public internet.
///
/// This two-level check avoids the common failure mode where a device
/// reports "connected" on a captive portal or NAT-only network but
/// cannot actually reach the backend.
///
/// ### Usage
/// ```dart
/// final service = ConnectivityService();
/// await service.initialise();
///
/// // Snapshot
/// print(service.isConnected);
///
/// // Reactive
/// service.statusStream.listen((status) { ... });
///
/// // Teardown
/// await service.dispose();
/// ```
final class ConnectivityService {
  /// Creates a [ConnectivityService].
  ///
  /// The [connectivity] and [internetConnection] parameters are exposed
  /// for dependency injection in tests. Production code should omit
  /// them; the defaults are used automatically.
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetConnection =
            internetConnection ?? InternetConnection();

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;

  ConnectivityStatus _status = ConnectivityStatus.disconnected;

  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  // ── Public surface ───────────────────────────────────────────────────────

  /// The most recently resolved connectivity status.
  ///
  /// This value is `ConnectivityStatus.disconnected` until
  /// [initialise] has been awaited at least once.
  ConnectivityStatus get status => _status;

  /// A broadcast [Stream] that emits a new [ConnectivityStatus]
  /// whenever the network state transitions.
  ///
  /// Multiple listeners are supported; all receive the same events.
  Stream<ConnectivityStatus> get statusStream => _controller.stream;

  /// `true` when [status] is [ConnectivityStatus.connected].
  bool get isConnected => _status == ConnectivityStatus.connected;

  /// `true` when [status] is [ConnectivityStatus.disconnected] or
  /// [ConnectivityStatus.noInternet].
  bool get isOffline => _status != ConnectivityStatus.connected;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Performs an eager connectivity check and begins listening for
  /// interface and internet-status changes.
  ///
  /// Must be awaited during the application bootstrap phase before
  /// [status] or [statusStream] are consumed.
  Future<void> initialise() async {
    await _refreshStatus();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_onInterfaceChanged);
    _internetSubscription =
        _internetConnection.onStatusChange.listen(_onInternetStatusChanged);
  }

  /// Cancels all active subscriptions and closes [statusStream].
  ///
  /// After this call the service must not be used again; create a new
  /// instance if connectivity monitoring is needed again.
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _internetSubscription?.cancel();
    await _controller.close();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<void> _refreshStatus() async {
    final results = await _connectivity.checkConnectivity();
    if (_hasNetworkInterface(results)) {
      final hasInternet = await _internetConnection.hasInternetAccess;
      _emit(
        hasInternet
            ? ConnectivityStatus.connected
            : ConnectivityStatus.noInternet,
      );
    } else {
      _emit(ConnectivityStatus.disconnected);
    }
  }

  void _onInterfaceChanged(List<ConnectivityResult> results) {
    if (!_hasNetworkInterface(results)) {
      _emit(ConnectivityStatus.disconnected);
      return;
    }
    // Interface is up — check actual internet access.
    _internetConnection.hasInternetAccess.then((hasInternet) {
      _emit(
        hasInternet
            ? ConnectivityStatus.connected
            : ConnectivityStatus.noInternet,
      );
    });
  }

  void _onInternetStatusChanged(InternetStatus internetStatus) {
    switch (internetStatus) {
      case InternetStatus.connected:
        _emit(ConnectivityStatus.connected);
      case InternetStatus.disconnected:
        // Determine whether we still have an interface.
        _connectivity.checkConnectivity().then((results) {
          _emit(
            _hasNetworkInterface(results)
                ? ConnectivityStatus.noInternet
                : ConnectivityStatus.disconnected,
          );
        });
    }
  }

  void _emit(ConnectivityStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    if (!_controller.isClosed) _controller.add(newStatus);
  }

  /// Returns `true` when [results] contains at least one non-none,
  /// non-bluetooth connectivity type, indicating a usable interface.
  static bool _hasNetworkInterface(List<ConnectivityResult> results) =>
      results.any(
        (r) =>
            r != ConnectivityResult.none &&
            r != ConnectivityResult.bluetooth,
      );
}
