import 'dart:io';
import 'package:flutter/services.dart';

class AutostartService {
  static const _channel = MethodChannel('com.igox.busylight_buddy/autostart');

  /// Returns true only on supported platforms (macOS, Windows)
  static bool get isSupported => Platform.isMacOS || Platform.isWindows;

  static Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } catch (_) {}
  }
}