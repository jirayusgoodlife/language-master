class ShadowingLine {
  final String id;
  final String japanese;
  final String romaji;
  final String thai;
  final int pauseDurationMs;
  final String tips;

  ShadowingLine({
    required this.id,
    required this.japanese,
    required this.romaji,
    required this.thai,
    required this.pauseDurationMs,
    required this.tips,
  });

  factory ShadowingLine.fromJson(Map<String, dynamic> json) {
    return ShadowingLine(
      id: json['id'] ?? '',
      japanese: json['japanese'] ?? '',
      romaji: json['romaji'] ?? '',
      thai: json['thai'] ?? '',
      pauseDurationMs: json['pauseDurationMs'] ?? 2000,
      tips: json['tips'] ?? '',
    );
  }
}

class NhkLesson {
  final String id;
  final int lessonNumber;
  final String title;
  final String scenario;
  final String difficulty;
  final String culturalTip;
  final Map<String, dynamic> keyPhrase;
  final List<dynamic> dialogue;
  final List<ShadowingLine> shadowingLines;

  NhkLesson({
    required this.id,
    required this.lessonNumber,
    required this.title,
    required this.scenario,
    required this.difficulty,
    required this.culturalTip,
    required this.keyPhrase,
    required this.dialogue,
    required this.shadowingLines,
  });

  factory NhkLesson.fromJson(Map<String, dynamic> json) {
    final sLines = (json['shadowingLines'] as List? ?? [])
        .map((e) => ShadowingLine.fromJson(e))
        .toList();

    return NhkLesson(
      id: json['id'] ?? '',
      lessonNumber: json['lessonNumber'] ?? 1,
      title: json['title'] ?? '',
      scenario: json['scenario'] ?? '',
      difficulty: json['difficulty'] ?? '',
      culturalTip: json['culturalTip'] ?? '',
      keyPhrase: json['keyPhrase'] ?? {},
      dialogue: json['dialogue'] ?? [],
      shadowingLines: sLines,
    );
  }
}
