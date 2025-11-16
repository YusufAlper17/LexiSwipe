import 'dart:convert';

class WordModel {
  final String id;
  final String word;
  final String type;
  final String level;
  final String pronunciation;
  final String audioUrl;
  final String englishMeaning;
  final String turkishMeaning;
  final List<Example> examples;

  WordModel({
    required this.id,
    required this.word,
    required this.type,
    required this.level,
    required this.pronunciation,
    required this.audioUrl,
    required this.englishMeaning,
    required this.turkishMeaning,
    required this.examples,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id']?.toString() ?? '',
      word: json['word']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      pronunciation: json['pronunciation']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString() ?? '',
      englishMeaning: json['english_meaning']?.toString() ?? '',
      turkishMeaning: json['turkish_meaning']?.toString() ?? '',
      examples: (json['examples'] as List?)
          ?.map((e) => Example.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'type': type,
    'level': level,
    'pronunciation': pronunciation,
    'audio_url': audioUrl,
    'english_meaning': englishMeaning,
    'turkish_meaning': turkishMeaning,
    'examples': examples.map((e) => {'english': e.english, 'turkish': e.turkish}).toList(),
  };

  static List<WordModel> decodeList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => WordModel.fromJson(json)).toList();
  }

  static String encodeList(List<WordModel> words) {
    return json.encode(words.map((word) => word.toJson()).toList());
  }
}

class Example {
  final String english;
  final String turkish;

  Example({
    required this.english,
    required this.turkish,
  });

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      english: json['english']?.toString() ?? '',
      turkish: json['turkish']?.toString() ?? '',
    );
  }
} 