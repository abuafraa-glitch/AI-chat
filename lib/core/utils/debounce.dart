import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class that introduces a delay before executing a function.
///
/// This is useful for scenarios like search input fields, where you want
/// to wait for a brief pause in user input before triggering a search.
final class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  final Duration delay;
  Timer? _timer;

  /// Calls [action] after a specified [delay].
  ///
  /// If [call] is invoked again before the [delay] expires, the previous
  /// call is cancelled and the timer is reset.
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels any pending debounced action.
  void dispose() {
    _timer?.cancel();
  }
}

/// A utility class that limits the rate at which a function can be called.
///
/// This is useful for scenarios like button presses or scroll events,
/// where you want to prevent a function from being executed too frequently.
final class Throttler {
  Throttler({this.interval = const Duration(milliseconds: 500)});

  final Duration interval;
  Timer? _timer;
  bool _canCall = true;

  /// Calls [action] immediately, then prevents further calls for [interval].
  ///
  /// If [call] is invoked again during the [interval], it is ignored.
  void call(VoidCallback action) {
    if (_canCall) {
      action();
      _canCall = false;
      _timer = Timer(interval, () {
        _canCall = true;
      });
    }
  }

  /// Cancels any pending throttled action and resets the call state.
  void dispose() {
    _timer?.cancel();
    _canCall = true;
  }
}
