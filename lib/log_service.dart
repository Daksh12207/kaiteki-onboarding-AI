// log_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Log {
  static const _tag = 'KAITEKI';

  static void i(String message) {
    debugPrint('[$_tag] $message');
  }

  static void e(String message, [Object? error, StackTrace? st]) {
    debugPrint('[$_tag][ERROR] $message');
    if (error != null) debugPrint('[$_tag][ERROR] $error');
    if (st != null) debugPrint('[$_tag][STACK] $st');
  }

  static String pp(dynamic data, {int indent = 2}) {
    try {
      final encoder = JsonEncoder.withIndent(' ' * indent);
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}