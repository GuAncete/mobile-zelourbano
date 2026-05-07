class TypeHelper {
  static const Map<String, String> tiposDetails = {
    '1': 'buraco',
    '2': 'iluminacao',
    '3': 'lixo',
    '4': 'saneamento',
    '5': 'arvore',
    '6': 'outro',
  };

  static String getText(String tipoId) {
    return tiposDetails[tipoId] ?? 'Outro';
  }

  static String getId(String tipoText) {
    var entry = tiposDetails.entries.firstWhere(
      (e) => e.value.toLowerCase() == tipoText.toLowerCase(),
      orElse: () => const MapEntry('6', 'outro'),
    );
    return entry.key;
  }

  static List<String> getValoresList() {
    return tiposDetails.values.toList();
  }
}
