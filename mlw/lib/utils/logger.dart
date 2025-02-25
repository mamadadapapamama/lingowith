import 'package:flutter/foundation.dart';

class Logger {
  static bool _enabled = true;
  
  static void enable() {
    _enabled = true;
  }
  
  static void disable() {
    _enabled = false;
  }
  
  static void log(String message, {String tag = 'App'}) {
    if (_enabled && kDebugMode) {
      print('[$tag] $message');
    }
  }
  
  static void error(String message, dynamic error, {String tag = 'Error'}) {
    if (_enabled && kDebugMode) {
      print('[$tag] $message: $error');
    }
  }
} 