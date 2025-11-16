class QuestionModel {
  final String word;
  final String partOfSpeech; // noun, verb, adjective etc.
  final String level; // A1, B2 etc.
  final String audioUrl;
  final String englishMeaning;
  final String turkishMeaning;
  final String pronunciation;
  final List<ExampleModel> examples;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;

  QuestionModel({
    required this.word,
    required this.partOfSpeech,
    required this.level,
    required this.audioUrl,
    required this.englishMeaning,
    required this.turkishMeaning,
    required this.pronunciation,
    required this.examples,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      word: json['word'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      level: json['level'] as String,
      audioUrl: json['audioUrl'] as String,
      englishMeaning: json['englishMeaning'] as String,
      turkishMeaning: json['turkishMeaning'] as String,
      pronunciation: json['pronunciation'] as String,
      examples: (json['examples'] as List<dynamic>)
          .map((e) => ExampleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      options: List<String>.from(json['options'] as List),
      correctOptionIndex: json['correctOptionIndex'] as int,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'partOfSpeech': partOfSpeech,
      'level': level,
      'audioUrl': audioUrl,
      'englishMeaning': englishMeaning,
      'turkishMeaning': turkishMeaning,
      'pronunciation': pronunciation,
      'examples': examples.map((e) => e.toJson()).toList(),
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }
}

class ExampleModel {
  final String english;
  final String turkish;

  ExampleModel({
    required this.english,
    required this.turkish,
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      english: json['english'] as String,
      turkish: json['turkish'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'turkish': turkish,
    };
  }
} 