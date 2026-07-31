import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A utility class for retrieving device-specific information and properties.
///
/// This class provides static methods to detect platform, screen dimensions,
/// orientation, and other device-related metrics. It is designed to be
/// easily extensible for future device-specific utilities.
abstract final class DeviceUtils {
  const DeviceUtils._();

  /// Returns the current [MediaQueryData] for the application.
  ///
  /// This getter should only be called after the [WidgetsBinding] has been
  /// initialized, typically after `runApp()`.
  static MediaQueryData get _mediaQueryData {
    final view = ui.PlatformDispatcher.instance.views.first;
    return MediaQueryData.fromView(view);
  }

  // ---------------------------------------------------------------------------
  // Platform Detection
  // ---------------------------------------------------------------------------

  /// Returns `true` if the current platform is Android.
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Returns `true` if the current platform is iOS.
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns `true` if the current platform is a web browser.
  static bool get isWeb => kIsWeb;

  /// Returns `true` if the current platform is a desktop operating system
  /// (Windows, macOS, Linux).
  static bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  /// Returns `true` if the current platform is a mobile operating system
  /// (Android, iOS).
  static bool get isMobile => isAndroid || isIOS;

  // ---------------------------------------------------------------------------
  // Screen Dimensions
  // ---------------------------------------------------------------------------

  /// Returns the current screen width in logical pixels.
  static double get screenWidth => _mediaQueryData.size.width;

  /// Returns the current screen height in logical pixels.
  static double get screenHeight => _mediaQueryData.size.height;

  /// Returns the current screen size in logical pixels.
  static Size get screenSize => _mediaQueryData.size;

  // ---------------------------------------------------------------------------
  // Orientation
  // ---------------------------------------------------------------------------

  /// Returns `true` if the device is currently in portrait mode.
  static bool get isPortrait =>
      _mediaQueryData.orientation == Orientation.portrait;

  /// Returns `true` if the device is currently in landscape mode.
  static bool get isLandscape =>
      _mediaQueryData.orientation == Orientation.landscape;

  // ---------------------------------------------------------------------------
  // Device Type Detection (Tablet/Phone)
  // ---------------------------------------------------------------------------

  /// Returns `true` if the device is likely a tablet.
  ///
  /// This is a heuristic based on screen width. A device is considered a
  /// tablet if its shortest side is greater than 600 logical pixels.
  static bool get isTablet {
    final shortestSide = _mediaQueryData.size.shortestSide;
    return shortestSide > 600;
  }

  /// Returns `true` if the device is likely a phone.
  static bool get isPhone => !isTablet;

  // ---------------------------------------------------------------------------
  // Density and Scaling
  // ---------------------------------------------------------------------------

  /// Returns the device pixel ratio.
  static double get pixelRatio => _mediaQueryData.devicePixelRatio;

  /// Returns the text scale factor.
  static double get textScaleFactor => _mediaQueryData.textScaler.scale(1);

  // ---------------------------------------------------------------------------
  // System UI Measurements
  // ---------------------------------------------------------------------------

  /// Returns the height of the top status bar in logical pixels.
  static double get statusBarHeight => _mediaQueryData.padding.top;

  /// Returns the height of the bottom system navigation bar in logical pixels.
  static double get bottomPadding => _mediaQueryData.padding.bottom;
}
