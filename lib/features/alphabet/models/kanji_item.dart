class KanjiVocab {
  final String word;
  final String reading;
  final String meaning;

  KanjiVocab({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  factory KanjiVocab.fromJson(Map<String, dynamic> json) {
    return KanjiVocab(
      word: json['word'] ?? '',
      reading: json['reading'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }
}

class KanjiItem {
  final String kanji;
  final int strokeCount;
  final String grade;
  final String meaning;
  final List<String> onyomi;
  final List<String> kunyomi;
  final String mnemonics;
  final String strokeGuide;
  final List<KanjiVocab> vocabulary;

  KanjiItem({
    required this.kanji,
    required this.strokeCount,
    required this.grade,
    required this.meaning,
    required this.onyomi,
    required this.kunyomi,
    required this.mnemonics,
    required this.strokeGuide,
    required this.vocabulary,
  });

  factory KanjiItem.fromJson(Map<String, dynamic> json) {
    final vocabList = (json['vocabulary'] as List? ?? [])
        .map((e) => KanjiVocab.fromJson(e))
        .toList();

    return KanjiItem(
      kanji: json['kanji'] ?? '',
      strokeCount: json['strokeCount'] ?? 1,
      grade: json['grade'] ?? 'N5',
      meaning: json['meaning'] ?? '',
      onyomi: List<String>.from(json['onyomi'] ?? []),
      kunyomi: List<String>.from(json['kunyomi'] ?? []),
      mnemonics: json['mnemonics'] ?? '',
      strokeGuide: json['strokeGuide'] ?? '',
      vocabulary: vocabList,
    );
  }
}
