import 'package:flutter/foundation.dart';

// lib/utils/constants.dart
class Constants {
  static String get apiUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api'; // Este é o IP certo pro Flutter Web!
    } else {
      return 'http://10.0.2.2:8000/api';
    }
  }
}

