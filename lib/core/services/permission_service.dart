import 'package:permission_handler/permission_handler.dart';

/// Describes the resolved outcome of a single permission request.
enum PermissionOutcome {
  /// The user granted the permission.
  granted,

  /// The user denied the permission but can be prompted again.
  denied,

  /// The user permanently denied the permission. The app must open the
  /// OS settings page to allow the user to grant it manually.
  permanentlyDenied,

  /// The permission is restricted by the OS or parental controls and
  /// cannot be granted by the user.
  restricted,

  /// The user granted limited access (iOS only, e.g. selected photos).
  limited,
}

/// A typed wrapper around the `permission_handler` package for the
/// Hajeen AI application.
///
/// All platform permission interactions must route through this service
/// so that:
/// - Callers are decoupled from the raw [Permission] / [PermissionStatus]
///   API surface.
/// - The common "check → request → handle permanently-denied" pattern is
///   expressed once in [request].
/// - Switching the underlying permission library requires changes only
///   in this class.
///
/// ### Usage
/// ```dart
/// final outcome = await permissionService.requestCamera();
/// if (outcome == PermissionOutcome.permanentlyDenied) {
///   await permissionService.openSettings();
/// }
/// ```
final class PermissionService {
  /// Creates a [PermissionService].
  ///
  /// The service is stateless and safe to share as a singleton.
  const PermissionService();

  // ── Status checks ─────────────────────────────────────────────────────────

  /// Returns the current [PermissionOutcome] for [permission] without
  /// showing a system dialog.
  Future<PermissionOutcome> checkStatus(Permission permission) async {
    final status = await permission.status;
    return _mapStatus(status);
  }

  /// Returns `true` if [permission] is currently granted.
  Future<bool> isGranted(Permission permission) async =>
      (await permission.status).isGranted;

  /// Returns `true` if [permission] has been permanently denied and
  /// can only be restored from OS settings.
  Future<bool> isPermanentlyDenied(Permission permission) async =>
      (await permission.status).isPermanentlyDenied;

  // ── Single request ────────────────────────────────────────────────────────

  /// Requests [permission] from the user and returns the resolved
  /// [PermissionOutcome].
  ///
  /// - If the permission is already granted the system dialog is not
  ///   shown and [PermissionOutcome.granted] is returned immediately.
  /// - If the permission has been permanently denied and
  ///   [openSettingsIfPermanentlyDenied] is `true`, this method opens
  ///   the OS application settings page. The return value is still
  ///   [PermissionOutcome.permanentlyDenied]; callers should re-check
  ///   when the app resumes.
  Future<PermissionOutcome> request(
    Permission permission, {
    bool openSettingsIfPermanentlyDenied = false,
  }) async {
    final current = await permission.status;

    if (current.isGranted || current.isLimited) {
      return _mapStatus(current);
    }

    if (current.isPermanentlyDenied) {
      if (openSettingsIfPermanentlyDenied) await openAppSettings();
      return PermissionOutcome.permanentlyDenied;
    }

    if (current.isRestricted) return PermissionOutcome.restricted;

    final result = await permission.request();
    return _mapStatus(result);
  }

  // ── Batch request ─────────────────────────────────────────────────────────

  /// Requests multiple [permissions] simultaneously and returns a map
  /// of each permission to its resolved [PermissionOutcome].
  Future<Map<Permission, PermissionOutcome>> requestAll(
    List<Permission> permissions,
  ) async {
    final statuses = await permissions.request();
    return statuses.map(
      (permission, status) => MapEntry(permission, _mapStatus(status)),
    );
  }

  // ── Domain helpers ────────────────────────────────────────────────────────

  /// Requests camera permission for photo capture in the chat input.
  Future<PermissionOutcome> requestCamera({
    bool openSettingsIfPermanentlyDenied = false,
  }) =>
      request(
        Permission.camera,
        openSettingsIfPermanentlyDenied: openSettingsIfPermanentlyDenied,
      );

  /// Requests access to the device photo library for file attachments.
  Future<PermissionOutcome> requestPhotos({
    bool openSettingsIfPermanentlyDenied = false,
  }) =>
      request(
        Permission.photos,
        openSettingsIfPermanentlyDenied: openSettingsIfPermanentlyDenied,
      );

  /// Requests notification permission for in-app and push alerts.
  Future<PermissionOutcome> requestNotifications({
    bool openSettingsIfPermanentlyDenied = false,
  }) =>
      request(
        Permission.notification,
        openSettingsIfPermanentlyDenied: openSettingsIfPermanentlyDenied,
      );

  /// Requests microphone permission for voice-input features.
  Future<PermissionOutcome> requestMicrophone({
    bool openSettingsIfPermanentlyDenied = false,
  }) =>
      request(
        Permission.microphone,
        openSettingsIfPermanentlyDenied: openSettingsIfPermanentlyDenied,
      );

  /// Requests storage permission for file download and management.
  ///
  /// On Android 13+ the granular media permissions are used instead of
  /// the broad storage permission; on older Android the broad
  /// [Permission.storage] is used via `permission_handler`'s internal
  /// routing.
  Future<PermissionOutcome> requestStorage({
    bool openSettingsIfPermanentlyDenied = false,
  }) =>
      request(
        Permission.storage,
        openSettingsIfPermanentlyDenied: openSettingsIfPermanentlyDenied,
      );

  // ── Settings ──────────────────────────────────────────────────────────────

  /// Opens the OS application settings page for this app so the user
  /// can manually grant a permanently-denied permission.
  ///
  /// Returns `true` if the settings page could be opened.
  Future<bool> openSettings() => openAppSettings();

  // ── Mapping ───────────────────────────────────────────────────────────────

  static PermissionOutcome _mapStatus(PermissionStatus status) {
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isLimited) return PermissionOutcome.limited;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;
    if (status.isRestricted) return PermissionOutcome.restricted;
    return PermissionOutcome.denied;
  }
}
