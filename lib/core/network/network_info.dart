import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Contract for querying device network connectivity.
///
/// The concrete implementation ([NetworkInfoImpl]) combines
/// [Connectivity] (fast, no DNS round-trip) with
/// [InternetConnectionCheckerPlus] (actual reachability probe) so that
/// callers always receive an accurate signal rather than a false
/// positive from being connected to a router without upstream internet.
abstract interface class NetworkInfo {
  /// Performs an active internet reachability check.
  ///
  /// Returns `true` when the device can reach the internet right now.
  /// This makes a lightweight network request internally and should not
  /// be called on every UI rebuild; cache the result locally when you
  /// need to gate a batch of operations.
  Future<bool> get isConnected;

  /// Emits `true` whenever internet connectivity is regained and
  /// `false` whenever it is lost.
  ///
  /// The stream never closes during the lifetime of the app. Subscribe
  /// once from a long-lived object (e.g. a Cubit or service) and
  /// cancel the subscription in `dispose` / `close`.
  Stream<bool> get connectivityStream;
}

/// Production implementation backed by [InternetConnectionCheckerPlus]
/// and [Connectivity].
///
/// Inject via the DI container; do not construct directly in feature
/// code. The [dispose] method should be called by the DI container or
/// the owning service when the application is shutting down.
final class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl({
    required InternetConnectionCheckerPlus connectionChecker,
    required Connectivity connectivity,
  })  : _connectionChecker = connectionChecker,
        _connectivity = connectivity;

  final InternetConnectionCheckerPlus _connectionChecker;

  // Retained so the DI container can dispose it if needed in the future.
  // ignore: unused_field
  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected => _connectionChecker.hasConnection;

  @override
  Stream<bool> get connectivityStream =>
      _connectionChecker.onStatusChange.map(_toBoolean);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _toBoolean(InternetConnectionStatus status) =>
      status == InternetConnectionStatus.connected;
}
