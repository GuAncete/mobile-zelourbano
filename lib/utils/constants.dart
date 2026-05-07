import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// lib/utils/constants.dart
class Constants {
  /// Retorna o host base.
  /// - Web: usa localhost
  /// - Android emulator: usa 10.0.2.2 (loopback para host)
  /// - Windows/macOS/Linux desktop: usa localhost
  static String get _baseHost {
    if (kIsWeb) return 'http://localhost:8000';
    // Plataformas desktop acessam localhost diretamente
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:8000';
    }
    // Android emulator usa o IP especial
    return 'http://10.0.2.2:8000';
  }

  static String get apiUrl => '$_baseHost/api';
  static String get storageUrl {
    if (kIsWeb) {
      return '$_baseHost/api/file';
    }
    return '$_baseHost/storage';
  }
}

