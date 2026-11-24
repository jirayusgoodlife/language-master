class MouthGuide {
  final String shapeName;
  final String instruction;
  final String thaiApproximation;
  final String lipOpening;
  final String tonguePosition;

  MouthGuide({
    required this.shapeName,
    required this.instruction,
    required this.thaiApproximation,
    required this.lipOpening,
    required this.tonguePosition,
  });

  factory MouthGuide.fromJson(Map<String, dynamic> json) {
    return MouthGuide(
      shapeName: json['shapeName'] ?? '',
      instruction: json['instruction'] ?? '',
      thaiApproximation: json['thaiApproximation'] ?? '',
      lipOpening: json['lipOpening'] ?? '',
      tonguePosition: json['tonguePosition'] ?? '',
    );
  }
}

class ExampleWord {
  final String word;
  final String reading;
  final String meaning;

  ExampleWord({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  factory ExampleWord.fromJson(Map<String, dynamic> json) {
    return ExampleWord(
      word: json['word'] ?? '',
      reading: json['reading'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }
}

class KanaChar {
  final String char;
  final String romaji;
  final String thai;
  final String category;
  final MouthGuide mouthGuide;
  final ExampleWord? exampleWord;
  final String? strokeImage;

  KanaChar({
    required this.char,
    required this.romaji,
    required this.thai,
    required this.category,
    required this.mouthGuide,
    this.exampleWord,
    this.strokeImage,
  });

  factory KanaChar.fromJson(Map<String, dynamic> json) {
    return KanaChar(
      char: json['char'] ?? '',
      romaji: json['romaji'] ?? '',
      thai: json['thai'] ?? '',
      category: json['category'] ?? '',
      mouthGuide: MouthGuide.fromJson(json['mouthGuide'] ?? {}),
      exampleWord: json['exampleWord'] != null
          ? ExampleWord.fromJson(json['exampleWord'])
          : null,
      strokeImage: json['strokeImage'],
    );
  }
}
