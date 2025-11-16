import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';

class WordBankService {
  static const String _wordBankKey = 'word_bank';
  final List<WordModel> _wordBank = [];
  
  // Singleton instance
  static final WordBankService _instance = WordBankService._internal();
  
  factory WordBankService() {
    return _instance;
  }
  
  WordBankService._internal();

  // Kelime bankasını yükle
  Future<List<WordModel>> loadWordBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? wordBankJson = prefs.getString(_wordBankKey);
      
      if (wordBankJson != null) {
        final List<WordModel> loadedWords = WordModel.decodeList(wordBankJson);
        _wordBank.clear();
        _wordBank.addAll(loadedWords);
      }
      return List.from(_wordBank);
    } catch (e) {
      print('Kelime bankası yüklenirken hata: $e');
      return [];
    }
  }

  // Kelime bankasını kaydet
  Future<bool> saveWordBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String wordBankJson = WordModel.encodeList(_wordBank);
      await prefs.setString(_wordBankKey, wordBankJson);
      return true;
    } catch (e) {
      print('Kelime bankası kaydedilirken hata: $e');
      return false;
    }
  }

  // Kelime bankasına kelime ekle
  Future<bool> addWordToBank(WordModel word) async {
    try {
      // Eğer kelime zaten varsa ekleme
      if (_wordBank.any((w) => w.id == word.id)) {
        return true;
      }
      
      _wordBank.add(word);
      return await saveWordBank();
    } catch (e) {
      print('Kelime bankasına kelime eklerken hata: $e');
      return false;
    }
  }

  // Oturum için kelime bankasına kelime ekle (geçici kelime bankası için)
  void addWordToSessionBank(WordModel word, List<WordModel> sessionBank) {
    if (!sessionBank.any((w) => w.id == word.id)) {
      sessionBank.add(word);
    }
  }

  // Kelime bankasından kelime çıkar
  Future<bool> removeWordFromBank(String wordId) async {
    try {
      _wordBank.removeWhere((word) => word.id == wordId);
      return await saveWordBank();
    } catch (e) {
      print('Kelime bankasından kelime çıkarırken hata: $e');
      return false;
    }
  }

  // Kelime bankasını temizle
  Future<bool> clearWordBank() async {
    try {
      _wordBank.clear();
      return await saveWordBank();
    } catch (e) {
      print('Kelime bankası temizlenirken hata: $e');
      return false;
    }
  }

  // Kelime bankasındaki kelime sayısını al
  int getWordBankCount() {
    return _wordBank.length;
  }

  // Belirtilen ID'ye sahip kelimeyi al
  WordModel? getWordById(String wordId) {
    try {
      return _wordBank.firstWhere((word) => word.id == wordId);
    } catch (e) {
      return null;
    }
  }
  
  // Kelime bankasının kopyasını al
  List<WordModel> getWordBankCopy() {
    return List.from(_wordBank);
  }
  
  // Belirli bir kelime kelime bankasında var mı
  bool isWordInBank(String wordId) {
    return _wordBank.any((word) => word.id == wordId);
  }

  Future<bool> clearWordsByLevel(String level) async {
    try {
      if (level == 'MIX') {
        return await clearWordBank();
      }
      
      _wordBank.removeWhere((word) => word.level.toUpperCase() == level);
      return await saveWordBank();
    } catch (e) {
      print('Kelime bankasından seviye temizlenirken hata: $e');
      return false;
    }
  }
} 