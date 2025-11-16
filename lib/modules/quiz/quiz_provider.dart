import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/question_model.dart';
import '../../models/word_model.dart';
import '../learn/word_card_page.dart';
import 'dart:async'; // Timer için ekledik
import '../../services/premium_service.dart'; // Premium servisini ekledik

enum QuizStatus {
  notStarted,
  inProgress,
  completed,
}

class QuizProvider extends ChangeNotifier {
  List<QuestionModel> _questions = [];
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  int? _selectedAnswer;
  bool _isCompleted = false;
  Map<String, QuizStatus> _quizStatuses = {};
  String? _currentCategory;
  String? _currentLevel;
  int? _currentExamNumber;
  DateTime? _startTime;
  Duration? _completionTime;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  // Word Bank ve Practice Mistakes için değişkenler
  List<WordModel> _viewedWords = [];
  List<String> _viewedWordIds = [];
  List<String> _practiceMistakes = [];
  Map<String, int> _mistakeCountsByLevel = {};
  
  // Aktif süre için değişkenler
  Duration _activeTime = Duration.zero;
  DateTime? _lastPauseTime;
  DateTime? _lastResumeTime;

  // Can sistemi için değişkenler
  static const int maxLives = 5;
  static const int liveRefreshHours = 4;
  int _remainingLives = maxLives;
  DateTime? _lastLivesRefreshTime;
  Timer? _livesTimer;
  int _currentScore = 0;
  
  // Kart hakkı sistemi için değişkenler
  static const int maxCards = 50;
  static const int cardRefreshHours = 4;
  int _remainingCards = maxCards;
  DateTime? _lastCardsRefreshTime;
  Timer? _cardsTimer;

  // Premium servisi
  final PremiumService _premiumService = PremiumService();
  PremiumService get premiumService => _premiumService;

  // Doğrudan hatalar listesi
  List<QuestionModel> _directMistakes = [];

  // Doğrudan hataları getir
  List<QuestionModel> get directMistakes => List.unmodifiable(_directMistakes);

  bool get isInitialized => _isInitialized;

  List<QuestionModel> get questions => _questions;
  QuestionModel? get currentQuestion => 
    _questions.isNotEmpty && _currentQuestionIndex < _questions.length 
      ? _questions[_currentQuestionIndex] 
      : null;
  int get currentQuestionIndex => _currentQuestionIndex;
  set currentQuestionIndex(int value) {
    if (value >= 0 && value < _questions.length) {
      _currentQuestionIndex = value;
      notifyListeners();
    }
  }
  List<int?> get userAnswers => 
    _userAnswers.isEmpty ? [] : List.unmodifiable(_userAnswers);
  int? get selectedAnswer => _selectedAnswer;
  bool get isCompleted => _isCompleted;
  String get progress => 
    _questions.isEmpty ? '0/0' : '${_currentQuestionIndex + 1}/${_questions.length}';
  Duration? get completionTime => _completionTime;
  String? get category => _currentCategory;

  // Can sistemi getter'ları
  int get remainingLives => _remainingLives;
  Duration get timeUntilNextLife {
    if (_lastLivesRefreshTime == null) return Duration.zero;
    final nextRefreshTime = _lastLivesRefreshTime!.add(Duration(hours: liveRefreshHours));
    final now = DateTime.now();
    if (now.isAfter(nextRefreshTime)) return Duration.zero;
    return nextRefreshTime.difference(now);
  }
  
  int get currentScore => _currentScore;

  // Kart hakkı sistemi getter'ları
  int get remainingCards => _remainingCards;
  Duration get timeUntilNextCard {
    if (_lastCardsRefreshTime == null) return Duration.zero;
    final nextRefreshTime = _lastCardsRefreshTime!.add(Duration(hours: cardRefreshHours));
    final now = DateTime.now();
    if (now.isAfter(nextRefreshTime)) return Duration.zero;
    return nextRefreshTime.difference(now);
  }

  // Word Bank ve Mistakes getter'ları
  List<WordModel> get viewedWords => List.unmodifiable(_viewedWords);
  List<String> get viewedWordIds => List.unmodifiable(_viewedWordIds);
  List<String> get practiceMistakes => List.unmodifiable(_practiceMistakes);
  Map<String, int> get mistakeCountsByLevel => Map.unmodifiable(_mistakeCountsByLevel);

  int getLastAnsweredQuestionIndex() {
    int lastAnsweredIndex = -1;
    for (int i = 0; i < _userAnswers.length; i++) {
      if (_userAnswers[i] != null) {
        lastAnsweredIndex = i;
      }
    }
    return lastAnsweredIndex;
  }

  int getLastVisitedQuestionIndex() {
    // Kullanıcının kaldığı son soruyu bul
    int lastAnsweredIndex = getLastAnsweredQuestionIndex();
    
    // Eğer hiç cevap verilmemiş soru yoksa veya son sorudaysa, mevcut indeksi döndür
    if (lastAnsweredIndex == -1 || lastAnsweredIndex >= _questions.length - 1) {
      return _currentQuestionIndex;
    }
    
    // Kullanıcının kaldığı son sorudan bir sonraki soruyu döndür
    return lastAnsweredIndex + 1;
  }

  QuizStatus getQuizStatus(String quizId) {
    return _quizStatuses[quizId] ?? QuizStatus.notStarted;
  }

  void setQuizStatus(String quizId, QuizStatus status) {
    _quizStatuses[quizId] = status;
    _saveQuizStatuses();
    _saveUnlockedLevels();
    notifyListeners();
  }

  void selectAnswer(int answerIndex) {
    if (_userAnswers[_currentQuestionIndex] != null) return;
    
    if (_selectedAnswer == answerIndex) {
      _userAnswers[_currentQuestionIndex] = answerIndex;
      final isCorrect = answerIndex == _questions[_currentQuestionIndex].correctOptionIndex;
      
      if (isCorrect) {
        _currentScore += 10;
        print('Doğru cevap verildi: ${_questions[_currentQuestionIndex].word}');
        
        // Eğer bu bir mistakes bölümünden gelen soruysa ve doğru yanıtlandıysa, hatalar listesinden kaldır
        if (_currentCategory == 'mistakes') {
          removeDirectMistake(_questions[_currentQuestionIndex].word);
          print('Doğru yanıtlanan soru hatalar listesinden kaldırıldı: ${_questions[_currentQuestionIndex].word}');
        }
      } else {
        print('Yanlış cevap verildi: ${_questions[_currentQuestionIndex].word}');
        
        // Yanlış cevaplanan soruyu doğrudan kaydet - tüm kategorilerde
        saveDirectMistake(_questions[_currentQuestionIndex]);
        print('Soru doğrudan hatalar listesine eklendi: ${_questions[_currentQuestionIndex].word}');
        
        // Practice veya mistakes kategorisinde yanlış cevap verildiğinde can azalt
        // Premium kullanıcıları için can azaltma işlemini atlayalım
        if (((_currentCategory == 'practice' || _currentCategory == 'mistakes')) && !_premiumService.isPremium) {
          // Can hakkını azalt
          _remainingLives--;
          // Can verilerini kaydet
          _saveLivesData();
          print('${_currentCategory} kategorisinde can hakkı azaltıldı. Kalan can: $_remainingLives');
        }
      }
      
      _selectedAnswer = null;
      saveUserAnswers('${_currentCategory}_${_currentLevel}_${_currentExamNumber}');
      notifyListeners();
    } else {
      _selectedAnswer = answerIndex;
      notifyListeners();
    }
  }

  Future<void> loadQuestions(String category, String level, int examNumber) async {
    try {
      if (!_isInitialized) {
        print('QuizProvider not initialized. Initializing...');
        await init();
      }
      
      // Practice ve mistakes kategorileri için can kontrolü yap
      // Premium kullanıcılar için atlama yap
      if ((category == 'practice' || category == 'mistakes') && !_premiumService.isPremium && !hasEnoughLives()) {
        throw Exception('Yeterli can hakkınız yok. Lütfen bekleyin.');
      }

      print('Loading questions for category: $category, level: $level, exam: $examNumber');
      
      _currentCategory = category;
      _currentLevel = level;
      _currentExamNumber = examNumber;
      String quizId = '${category}_${level}_$examNumber';
      
      print('Quiz ID: $quizId');

      // Kategori için doğru JSON dosyasını seç
      String jsonFile;
      if (category == 'practice') {
        // Practice kategorisi için seviyeye göre JSON dosyasını seç
        switch (level.toUpperCase()) {
          case 'A1':
          case 'A2':
          case 'B1':
          case 'B2':
            jsonFile = 'assets/data/The_Oxford_3000.json';
            break;
          case 'C1':
          case 'C2':
            jsonFile = 'assets/data/The_Oxford_5000.json';
            break;
          case 'MIX':
            // Mix seviyesi için Oxford 3000 kelimelerini kullan
            jsonFile = 'assets/data/The_Oxford_3000.json';
            break;
          default:
            throw Exception('Geçersiz seviye: $level');
        }
      } else {
        // Diğer kategoriler için normal seçim - MIX seviyesi için de aynı dosyaları kullan
        switch (category) {
          case 'oxford_3000':
            jsonFile = 'assets/data/The_Oxford_3000.json';
            break;
          case 'oxford_5000':
            jsonFile = 'assets/data/The_Oxford_5000.json';
            break;
          case 'american_3000':
            jsonFile = 'assets/data/American_Oxford_3000.json';
            break;
          case 'american_5000':
            jsonFile = 'assets/data/American_Oxford_5000.json';
            break;
          default:
            throw Exception('Geçersiz kategori: $category');
        }
      }

      print('Loading words from $jsonFile');
      String jsonString;
      try {
        final ByteData data = await rootBundle.load(jsonFile);
        jsonString = utf8.decode(data.buffer.asUint8List());
        
        if (jsonString.isEmpty) {
          throw Exception('Kelime dosyası boş');
        }
        print('JSON string loaded successfully');
      } catch (e) {
        print('Error loading JSON file: $e');
        throw Exception('Kelimeler yüklenirken hata oluştu. Lütfen uygulamayı yeniden başlatın.');
      }

      // Parse JSON and create WordModel objects
      List<WordModel> allWords = [];
      try {
        final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
        print('JSON decoded successfully, found ${jsonList.length} items');
        
        for (var item in jsonList) {
          try {
            if (item is Map<String, dynamic>) {
              final word = WordModel.fromJson(item);
              allWords.add(word);
            }
          } catch (e) {
            print('Error parsing word: $e');
            // Continue with next word
          }
        }
            
        print('Successfully parsed ${allWords.length} words');
        
        if (allWords.isEmpty) {
          throw Exception('Veri dosyasında geçerli kelime bulunamadı');
        }
      } catch (e) {
        print('Error parsing JSON: $e');
        throw Exception('Kelime verisi işlenirken hata oluştu. Lütfen veri formatını kontrol edin.');
      }

      // Filter words by level
      print('Filtering words for level: $level');
      String mappedLevel = _mapLevel(level);
      print('Mapped level: $mappedLevel');
      List<WordModel> levelWords;
      
      // MIX seviyesi için tüm kelimeleri kullan, filtreleme yapma
      if (mappedLevel == 'MIX') {
        levelWords = allWords;
        print('MIX seviyesi seçildi, tüm kelimeler kullanılıyor: ${levelWords.length} kelime');
      } else {
        // Diğer seviyeler için normal filtreleme yap
        levelWords = allWords
            .where((word) => word.level.trim().toUpperCase() == mappedLevel)
            .toList();
        print('Found ${levelWords.length} words matching level $mappedLevel');
      }
      
      if (levelWords.isEmpty) {
        throw Exception('$level seviyesi için kelime bulunamadı');
      }

      // Create a copy for remaining words to avoid duplicates in options
      final List<WordModel> remainingWords = List.from(levelWords);
      print('Remaining words initialized with ${remainingWords.length} words');

      // Shuffle all words for randomization
      levelWords.shuffle();
      final questionWords = levelWords;  // Use all words instead of taking just 10
      
      // Create questions
      _questions = [];
      for (var word in questionWords) {
        // Remove current word from remaining words to avoid duplicate options
        remainingWords.removeWhere((w) => w.id == word.id);
        
        // Shuffle remaining words and take 4 for incorrect options
        remainingWords.shuffle();
        final incorrectOptions = remainingWords
            .take(4)
            .map((w) => w.turkishMeaning)
            .toList();
        
        // Add correct option and shuffle
        final allOptions = [...incorrectOptions, word.turkishMeaning];
        allOptions.shuffle();
        
        final correctIndex = allOptions.indexOf(word.turkishMeaning);
        
        _questions.add(QuestionModel(
          word: word.word,
          partOfSpeech: word.type,
          level: word.level,
          audioUrl: word.audioUrl,
          englishMeaning: word.englishMeaning,
          turkishMeaning: word.turkishMeaning,
          pronunciation: word.pronunciation,
          examples: word.examples.map((e) => ExampleModel(
            english: e.english,
            turkish: e.turkish,
          )).toList(),
          options: allOptions,
          correctOptionIndex: correctIndex,
          explanation: null,
        ));
        
        // Put the word back into remaining words for next questions
        remainingWords.add(word);
      }

      if (_questions.isEmpty) {
        throw Exception('Hiç soru oluşturulamadı');
      }

      print('Successfully created ${_questions.length} questions');
      
      // Initialize user answers
      _userAnswers = List.filled(_questions.length, null);

      // Check quiz status
      final quizStatus = getQuizStatus(quizId);
      if (quizStatus == QuizStatus.completed) {
        await loadQuizProgress(quizId);
        _isCompleted = true;
      } else if (quizStatus == QuizStatus.inProgress) {
        await loadInProgressQuiz(quizId);
        _isCompleted = false;
      } else {
        _isCompleted = false;
        _startTime = DateTime.now();
        _lastResumeTime = DateTime.now();
        _completionTime = null;
        _currentQuestionIndex = 0;
        _userAnswers = List.filled(_questions.length, null);
        _activeTime = Duration.zero;
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error in loadQuestions: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _selectedAnswer = null;
      saveUserAnswers('${_currentCategory}_${_currentLevel}_${_currentExamNumber}');
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      _selectedAnswer = null;
      saveUserAnswers('${_currentCategory}_${_currentLevel}_${_currentExamNumber}');
      notifyListeners();
    }
  }

  int getCorrectAnswersCount() {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] != null && _userAnswers[i] == _questions[i].correctOptionIndex) {
        count++;
      }
    }
    return count;
  }

  int getIncorrectAnswersCount() {
    int count = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] != null && _userAnswers[i] != _questions[i].correctOptionIndex) {
        count++;
      }
    }
    return count;
  }

  int getEmptyAnswersCount() {
    return _questions.length - getCorrectAnswersCount() - getIncorrectAnswersCount();
  }

  double getScore() {
    return getCorrectAnswersCount() * 10.0;
  }

  bool isAnswerCorrect(int questionIndex) {
    return _userAnswers[questionIndex] == _questions[questionIndex].correctOptionIndex;
  }

  void reset() {
    String quizId = '${_currentCategory}_${_currentLevel}_${_currentExamNumber}';
    _quizStatuses[quizId] = QuizStatus.notStarted;
    _currentQuestionIndex = 0;
    _userAnswers = List.filled(_questions.length, null);
    _selectedAnswer = null;
    _isCompleted = false;
    _remainingLives = maxLives;
    _currentScore = 0;
    
    // Süre değerlerini sıfırla
    _startTime = DateTime.now();
    _lastResumeTime = DateTime.now();
    _activeTime = Duration.zero;
    _completionTime = null;
    _lastPauseTime = null;
    
    // Sıfırlanan testin verilerini sil
    _prefs?.remove('${quizId}_data');
    
    // Quiz durumlarını ve seviye kilitlerini kaydet
    _saveQuizStatuses();
    _saveUnlockedLevels();
    
    notifyListeners();
  }

  void completeQuiz() {
    String quizId = '${_currentCategory}_${_currentLevel}_${_currentExamNumber}';
    _quizStatuses[quizId] = QuizStatus.completed;
    _isCompleted = true;
    
    // Son aktif süreyi hesapla
    if (_lastResumeTime != null) {
      _activeTime += DateTime.now().difference(_lastResumeTime!);
      _lastResumeTime = null;
    }
    _completionTime = _activeTime;
    
    // Quiz durumlarını ve seviye kilitlerini kaydet
    _saveQuizStatuses();
    _saveUnlockedLevels();
    
    notifyListeners();
  }

  bool isLevelCompleted(String category, String level) {
    // Bir seviyedeki tüm denemelerin tamamlanıp tamamlanmadığını kontrol et
    for (int examNumber = 1; examNumber <= 10; examNumber++) {
      String quizId = '${category}_${level}_$examNumber';
      if (getQuizStatus(quizId) != QuizStatus.completed) {
        return false;
      }
    }
    return true;
  }

  void unlockNextLevel(String category, String level) {
    // Eğer mevcut seviye tamamlandıysa, bir sonraki seviyenin kilidini aç
    if (isLevelCompleted(category, level)) {
      String nextLevelKey = '${category}_${level}_unlocked';
      _quizStatuses[nextLevelKey] = QuizStatus.notStarted;
      _saveUnlockedLevels();
      notifyListeners();
    }
  }

  bool isLevelUnlocked(String category, String level) {
    if (level == '1') return true; // İlk seviye her zaman açık
    String levelKey = '${category}_${level}_unlocked';
    return _quizStatuses[levelKey] != null;
  }

  // SharedPreferences'ı başlat
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('QuizProvider already initialized');
      return;
    }
    
    try {
      // SharedPreferences'ı başlat
      _prefs = await SharedPreferences.getInstance();
      debugPrint('SharedPreferences initialized successfully');
      
      // Kaydedilmiş ilerlemeyi yükle
      await _loadSavedProgress();
      
      // Doğrudan kaydedilen hataları yükle
      await _loadDirectMistakesFromPrefs();
      
      // İlk seviyeyi her zaman aç (eğer hiç ilerleme yoksa)
      if (_quizStatuses.isEmpty) {
        _quizStatuses['ilkokul_1_unlocked'] = QuizStatus.notStarted;
        _quizStatuses['ortaokul_1_unlocked'] = QuizStatus.notStarted;
        _quizStatuses['lise_1_unlocked'] = QuizStatus.notStarted;
        await _saveQuizStatuses();
      }
      
      await initLives(); // Can sistemini başlat
      await initCards(); // Kart hakkı sistemini başlat
      
      _isInitialized = true;
      notifyListeners();
      debugPrint('QuizProvider initialization completed');
    } catch (e) {
      debugPrint('Error initializing QuizProvider: $e');
      _resetProgress();
      _isInitialized = false;
      notifyListeners();
    }
  }

  // Kaydedilmiş ilerlemeyi yükle
  Future<void> _loadSavedProgress() async {
    try {
      // Quiz durumlarını yükle
      final statusesString = _prefs!.getString('quiz_statuses');
      if (statusesString != null) {
        final statusesMap = json.decode(statusesString) as Map<String, dynamic>;
        _quizStatuses = statusesMap.map(
          (key, value) => MapEntry(key, QuizStatus.values.firstWhere(
            (status) => status.toString() == value,
            orElse: () => QuizStatus.notStarted,
          )),
        );
      }

      // Seviye kilitlerini yükle
      final unlockedLevels = _prefs!.getStringList('unlocked_levels');
      if (unlockedLevels != null) {
        for (final key in unlockedLevels) {
          _quizStatuses[key] = QuizStatus.notStarted;
        }
      }

      debugPrint('Saved progress loaded successfully');
    } catch (e) {
      debugPrint('Error loading saved progress: $e');
      _resetProgress();
    }
  }

  // Quiz durumlarını kaydet
  Future<void> _saveQuizStatuses() async {
    if (_prefs == null) return;
    
    try {
      final statusesMap = _quizStatuses.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      await _prefs!.setString('quiz_statuses', json.encode(statusesMap));
      
      // Açık olan seviyeleri kaydet
      final unlockedLevels = _quizStatuses.entries
          .where((entry) => entry.key.endsWith('_unlocked'))
          .map((entry) => entry.key)
          .toList();
      await _prefs!.setStringList('unlocked_levels', unlockedLevels);
      
      debugPrint('Quiz statuses and unlocked levels saved successfully');
    } catch (e) {
      debugPrint('Error saving quiz statuses: $e');
    }
  }

  // İlerleme durumunu sıfırla
  void _resetProgress() {
    _questions = [];
    _userAnswers = [];
    _currentQuestionIndex = 0;
    _selectedAnswer = null;
    _isCompleted = false;
    _quizStatuses = {
      'ilkokul_1_unlocked': QuizStatus.notStarted,
      'ortaokul_1_unlocked': QuizStatus.notStarted,
      'lise_1_unlocked': QuizStatus.notStarted
    };
    _currentCategory = null;
    _currentLevel = null;
    _currentExamNumber = null;
    _startTime = null;
    _completionTime = null;
    _activeTime = Duration.zero;
    _lastPauseTime = null;
    _lastResumeTime = null;
  }

  // Tüm ilerlemeyi temizle
  Future<void> clearAllProgress() async {
    if (_prefs == null) return;

    try {
      // Tüm ilerleme verilerini temizle
      final allKeys = _prefs!.getKeys().toList();
      for (final key in allKeys) {
        if (key.contains('_status') || 
            key.contains('_data') || 
            key.contains('_answers') ||
            key == 'quiz_statuses' ||
            key == 'unlocked_levels') {
          await _prefs!.remove(key);
        }
      }

      // İlerleme durumunu sıfırla
      _resetProgress();
      
      // İlk seviyeleri tekrar aç
      await _saveQuizStatuses();

      notifyListeners();
      debugPrint('All progress cleared successfully');
    } catch (e) {
      debugPrint('Error clearing progress: $e');
    }
  }

  // Quiz durumlarını yükle
  Future<void> _loadQuizStatuses() async {
    if (_prefs == null) {
      print('SharedPreferences is null, skipping loading quiz statuses');
      return;
    }
    
    try {
      final statusesString = _prefs!.getString('quiz_statuses');
      if (statusesString != null) {
        final statusesMap = json.decode(statusesString) as Map<String, dynamic>;
        _quizStatuses = statusesMap.map(
          (key, value) => MapEntry(key, QuizStatus.values.firstWhere(
            (status) => status.toString() == value,
            orElse: () => QuizStatus.notStarted,
          )),
        );
        print('Loaded ${_quizStatuses.length} quiz statuses');
        notifyListeners();
      } else {
        print('No saved quiz statuses found');
      }
    } catch (e) {
      print('Error loading quiz statuses: $e');
      _quizStatuses = {};
    }
  }

  // Kayıtlı seviye kilitlerini yükle
  Future<void> _loadUnlockedLevels() async {
    if (_prefs == null) return;
    
    try {
      final unlockedLevels = _prefs!.getStringList('unlocked_levels');
      if (unlockedLevels != null) {
        for (final key in unlockedLevels) {
          _quizStatuses[key] = QuizStatus.notStarted;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading unlocked levels: $e');
    }
  }

  // Seviye kilidini kaydet
  Future<void> _saveUnlockedLevels() async {
    if (_prefs == null) return;
    
    try {
      final unlockedLevels = <String>[];
      for (final key in _quizStatuses.keys) {
        if (key.endsWith('_unlocked')) {
          unlockedLevels.add(key);
        }
      }
      await _prefs!.setStringList('unlocked_levels', unlockedLevels);
      print('Unlocked levels saved successfully');
    } catch (e) {
      print('Error saving unlocked levels: $e');
    }
  }

  // Kullanıcı cevaplarını kaydet
  Future<void> saveUserAnswers(String quizId) async {
    if (_prefs == null) {
      print('SharedPreferences is null, skipping saving user answers');
      return;
    }
    
    try {
      final answersMap = {
        'answers': _userAnswers.map((answer) => answer?.toString()).toList(),
        'currentIndex': _currentQuestionIndex,
        'startTime': _startTime?.millisecondsSinceEpoch,
        'category': _currentCategory,
        'level': _currentLevel,
        'examNumber': _currentExamNumber,
      };
      
      final jsonString = json.encode(answersMap);
      await _prefs!.setString('answers_$quizId', jsonString);
      print('Saved user answers for quiz: $quizId');
    } catch (e) {
      print('Error saving user answers: $e');
    }
  }

  // Kullanıcı cevaplarını yükle
  Future<void> _loadUserAnswers(String quizId) async {
    if (_prefs == null) {
      print('SharedPreferences is null, skipping loading user answers');
      return;
    }
    
    try {
      final answersString = _prefs!.getString('answers_$quizId');
      if (answersString != null) {
        final answersMap = json.decode(answersString) as Map<String, dynamic>;
        
        // Cevapları string'den int'e dönüştür
        final answersList = (answersMap['answers'] as List).map((answer) {
          if (answer == null || answer == 'null') return null;
          return int.tryParse(answer.toString());
        }).toList();
        
        _userAnswers = answersList;
        _currentQuestionIndex = answersMap['currentIndex'] as int;
        
        final startTimeMillis = answersMap['startTime'] as int?;
        if (startTimeMillis != null) {
          _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        }
        
        print('Loaded user answers for quiz: $quizId');
        notifyListeners();
      } else {
        print('No saved answers found for quiz: $quizId');
      }
    } catch (e) {
      print('Error loading user answers: $e');
      _userAnswers = [];
      _currentQuestionIndex = 0;
    }
  }

  int calculateScore() {
    return getScore().round();
  }

  String getCompletionTime() {
    Duration totalTime = _activeTime;
    if (_lastResumeTime != null && !_isCompleted) {
      totalTime += DateTime.now().difference(_lastResumeTime!);
    }
    
    int minutes = totalTime.inMinutes;
    int seconds = totalTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Aktif süreyi durduran metod
  void pauseTimer() {
    if (_lastResumeTime != null) {
      _lastPauseTime = DateTime.now();
      _activeTime += _lastPauseTime!.difference(_lastResumeTime!);
      _lastResumeTime = null;
      print('Timer paused. Active time: ${_activeTime.inSeconds} seconds');
    }
  }

  // Aktif süreyi devam ettiren metod
  void resumeTimer() {
    if (!_isCompleted) {
      _lastResumeTime = DateTime.now();
      print('Timer resumed');
    }
  }

  // Quiz ilerlemesini kaydetmek için yeni metodlar
  Future<void> saveQuizProgress(String quizId) async {
    if (_prefs == null) return;

    // Quiz durumunu kaydet
    await _prefs!.setString('${quizId}_status', QuizStatus.completed.toString());
    
    // Kullanıcının cevaplarını kaydet
    final quizData = {
      'answers': _userAnswers,
      'score': calculateScore(),
      'completion_time': _completionTime?.inSeconds,
      'correct_count': getCorrectAnswersCount(),
      'incorrect_count': getIncorrectAnswersCount(),
      'empty_count': getEmptyAnswersCount()
    };
    
    await _prefs!.setString('${quizId}_data', json.encode(quizData));
    
    // En yüksek puanı güncelle
    saveHighScore(quizId, calculateScore());
  }

  // Quiz ilerlemesini yüklemek için yeni metod
  Future<void> loadQuizProgress(String quizId) async {
    if (_prefs == null) return;

    // Quiz verilerini yükle
    final savedData = _prefs!.getString('${quizId}_data');
    if (savedData != null) {
      final quizData = json.decode(savedData) as Map<String, dynamic>;
      
      // Cevapları yükle
      _userAnswers = List<int?>.from(quizData['answers'].map((answer) {
        if (answer == null) return null;
        return int.tryParse(answer.toString());
      }));

      // Tamamlanma süresini yükle
      final savedCompletionTime = quizData['completion_time'];
      if (savedCompletionTime != null) {
        _completionTime = Duration(seconds: savedCompletionTime);
      }
    }
  }

  // Yarım kalan quiz'i kaydet
  Future<void> saveInProgressQuiz(String quizId) async {
    if (_prefs == null) return;

    try {
      // Quiz durumunu kaydet
      await _prefs!.setString('${quizId}_status', QuizStatus.inProgress.toString());
      
      // Mevcut ilerlemeyi kaydet
      final progressData = {
        'answers': _userAnswers,
        'currentIndex': _currentQuestionIndex,
        'active_time': _activeTime.inSeconds,
        'start_time': _startTime?.millisecondsSinceEpoch
      };
      
      await _prefs!.setString('${quizId}_progress', json.encode(progressData));
      debugPrint('Quiz progress saved successfully');
    } catch (e) {
      debugPrint('Error saving quiz progress: $e');
    }
  }

  // Yarım kalan quiz'i yükle
  Future<void> loadInProgressQuiz(String quizId) async {
    if (_prefs == null) return;

    try {
      final savedProgress = _prefs!.getString('${quizId}_progress');
      if (savedProgress != null) {
        final progressData = json.decode(savedProgress) as Map<String, dynamic>;
        
        // Cevapları yükle
        _userAnswers = List<int?>.from(progressData['answers'].map((answer) {
          if (answer == null) return null;
          return int.tryParse(answer.toString());
        }));
        
        // Mevcut soruyu yükle
        _currentQuestionIndex = progressData['currentIndex'] as int;
        
        // Süreyi yükle
        _activeTime = Duration(seconds: progressData['active_time'] as int);
        
        // Başlangıç zamanını yükle
        final startTimeMillis = progressData['start_time'] as int?;
        if (startTimeMillis != null) {
          _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        }
        
        // Süreyi başlat
        _lastResumeTime = DateTime.now();
        
        debugPrint('Quiz progress loaded successfully');
      }
    } catch (e) {
      debugPrint('Error loading quiz progress: $e');
    }
  }

  @override
  void dispose() {
    // Provider dispose edildiğinde süreyi durdur ve ilerlemeyi kaydet
    if (!_isCompleted && _currentCategory != null) {
      pauseTimer();
      String quizId = '${_currentCategory}_${_currentLevel}_${_currentExamNumber}';
      saveInProgressQuiz(quizId);
    }
    _livesTimer?.cancel();
    _cardsTimer?.cancel();
    super.dispose();
  }

  // Seviye adını JSON dosyasındaki formata dönüştür
  String _mapLevel(String level) {
    // Seviye adını küçük harfe çevir ve boşlukları kaldır
    level = level.toLowerCase().replaceAll(' ', '');
    
    // Seviye eşleştirmelerini yap
    switch (level) {
      case 'a1':
        return 'A1';
      case 'a2':
        return 'A2';
      case 'b1':
        return 'B1';
      case 'b2':
        return 'B2';
      case 'c1':
        return 'C1';
      default:
        return level.toUpperCase();
    }
  }

  // Doğrudan hata kaydet
  Future<void> saveDirectMistake(QuestionModel question) async {
    try {
      print('Doğrudan hata kaydediliyor: ${question.word}');
      
      // Eğer _directMistakes boşsa, önce SharedPreferences'dan yükle
      if (_directMistakes.isEmpty) {
        await _loadDirectMistakesFromPrefs();
      }
      
      // Eğer kelime zaten hatalar listesinde varsa, ekleme
      bool alreadyExists = _directMistakes.any((q) => q.word == question.word);
      if (alreadyExists) {
        print('${question.word} kelimesi zaten hatalar listesinde var, tekrar eklenmedi.');
        return;
      }
      
      // Hatayı listeye ekle
      _directMistakes.add(question);
      
      // SharedPreferences'a kaydet
      await _saveDirectMistakesToPrefs();
      
      print('Doğrudan hata başarıyla kaydedildi: ${question.word}');
        } catch (e) {
      print('Doğrudan hata kaydedilirken hata oluştu: $e');
    }
  }

  // Doğrudan hataları SharedPreferences'a kaydet
  Future<void> _saveDirectMistakesToPrefs() async {
    try {
      if (_prefs == null) {
        print('SharedPreferences null, doğrudan hatalar kaydedilemedi');
        return;
      }
      
      // QuestionModel listesini JSON'a dönüştür
      final jsonList = _directMistakes.map((q) => q.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      // SharedPreferences'a kaydet
      await _prefs!.setString('direct_mistakes_data', jsonString);
      print('Doğrudan hatalar SharedPreferences\'a kaydedildi. Toplam: ${_directMistakes.length}');
        } catch (e) {
      print('Doğrudan hatalar SharedPreferences\'a kaydedilirken hata oluştu: $e');
    }
  }

  // Doğrudan hataları SharedPreferences'dan yükle
  Future<void> _loadDirectMistakesFromPrefs() async {
    try {
      if (_prefs == null) {
        print('SharedPreferences null, doğrudan hatalar yüklenemedi');
        return;
      }
      
      final jsonString = _prefs!.getString('direct_mistakes_data');
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = json.decode(jsonString) as List<dynamic>;
        _directMistakes = jsonList
            .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        print('Doğrudan hatalar SharedPreferences\'dan yüklendi. Toplam: ${_directMistakes.length}');
      } else {
        _directMistakes = [];
        print('SharedPreferences\'da doğrudan hata bulunamadı, boş liste oluşturuldu');
      }
    } catch (e) {
      print("Doğrudan hatalar SharedPreferences'dan yüklenirken hata oluştu: $e");
      _directMistakes = [];
    }
  }

  // Doğrudan hataları getir
  Future<List<QuestionModel>> getDirectMistakes() async {
    try {
      // Eğer _directMistakes boşsa, önce SharedPreferences'dan yükle
      if (_directMistakes.isEmpty) {
        await _loadDirectMistakesFromPrefs();
      }
      
      // Hataları karıştır ve döndür
      final shuffledMistakes = List<QuestionModel>.from(_directMistakes)..shuffle();
      
      print('Doğrudan hatalar getirildi. Toplam: ${shuffledMistakes.length}');
      if (shuffledMistakes.isEmpty) {
        print('Hiç doğrudan hata bulunamadı');
      }
      
      return shuffledMistakes;
    } catch (e) {
      print('Doğrudan hatalar getirilirken hata oluştu: $e');
      return [];
    }
  }

  // Doğrudan hatayı kaldır
  Future<void> removeDirectMistake(String word) async {
    try {
      print('Doğrudan hata kaldırılıyor: $word');
      
      // Eğer _directMistakes boşsa, önce SharedPreferences'dan yükle
      if (_directMistakes.isEmpty) {
        await _loadDirectMistakesFromPrefs();
      }
      
      // Kelimeyi hatalar listesinden kaldır
      _directMistakes.removeWhere((q) => q.word == word);
      
      // SharedPreferences'a kaydet
      await _saveDirectMistakesToPrefs();
      
      print('Doğrudan hata başarıyla kaldırıldı: $word');
      } catch (e) {
      print('Doğrudan hata kaldırılırken hata oluştu: $e');
    }
  }

  // Tüm doğrudan hataları temizle
  Future<void> clearAllDirectMistakes() async {
    try {
      print('Tüm doğrudan hatalar temizleniyor. Mevcut hata sayısı: ${_directMistakes.length}');
      
      // Listeyi temizle
      _directMistakes.clear();
      
      // SharedPreferences'dan kaldır
      if (_prefs != null) {
        await _prefs!.remove('direct_mistakes_data');
      }
      
      print('Tüm doğrudan hatalar başarıyla temizlendi');
    } catch (e) {
      print('Tüm doğrudan hatalar temizlenirken hata oluştu: $e');
    }
  }

  // En yüksek puanı kaydetmek için yeni metod
  Future<void> saveHighScore(String quizId, int score) async {
    if (_prefs == null) return;
    
    try {
      // Mevcut en yüksek puanı kontrol et
      final savedHighScore = _prefs!.getInt('${quizId}_high_score') ?? 0;
      
      // Eğer yeni puan daha yüksekse kaydet
      if (score > savedHighScore) {
        await _prefs!.setInt('${quizId}_high_score', score);
        print('Yeni yüksek puan kaydedildi: $score');
      }
    } catch (e) {
      print('En yüksek puan kaydedilirken hata: $e');
    }
  }
  
  // En yüksek puanı getirmek için yeni metod
  int getHighScore(String quizId) {
    if (_prefs == null) return 0;
    return _prefs!.getInt('${quizId}_high_score') ?? 0;
  }

  // Can sistemi için metotlar
  Future<void> initLives() async {
    if (_prefs == null) await init();
    
    _remainingLives = _prefs!.getInt('remaining_lives') ?? maxLives;
    final lastRefreshTimeStr = _prefs!.getString('last_lives_refresh_time');
    
    if (lastRefreshTimeStr != null) {
      _lastLivesRefreshTime = DateTime.parse(lastRefreshTimeStr);
      _checkLivesRefresh();
    } else {
      _lastLivesRefreshTime = DateTime.now();
      await _saveLivesData();
    }
    
    // Timer'ı başlat
    _startLivesTimer();
  }
  
  void _startLivesTimer() {
    // Önceki timer varsa temizle
    _livesTimer?.cancel();
    
    // Her dakika kontrol edecek timer başlat
    _livesTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkLivesRefresh();
    });
  }
  
  void _checkLivesRefresh() {
    if (_lastLivesRefreshTime == null) return;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLivesRefreshTime!);
    
    if (difference.inHours >= liveRefreshHours && _remainingLives < maxLives) {
      // Kaç kez refresh olacağını hesapla
      final refreshCount = difference.inHours ~/ liveRefreshHours;
      
      // Her refresh için 5 can ekle ama maksimum can sayısını geçme
      int newLives = _remainingLives + (refreshCount * maxLives);
      if (newLives > maxLives) newLives = maxLives;
      
      // Son refresh zamanını güncelle
      _lastLivesRefreshTime = _lastLivesRefreshTime!.add(
        Duration(hours: refreshCount * liveRefreshHours)
      );
      
      if (_remainingLives != newLives) {
        _remainingLives = newLives;
        _saveLivesData();
        notifyListeners();
      }
    }
  }
  
  Future<void> _saveLivesData() async {
    if (_prefs == null) return;
    
    await _prefs!.setInt('remaining_lives', _remainingLives);
    if (_lastLivesRefreshTime != null) {
      await _prefs!.setString('last_lives_refresh_time', _lastLivesRefreshTime!.toIso8601String());
    }
  }
  
  bool hasEnoughLives() {
    // Premium kullanıcıları için her zaman yeterli can vardır
    if (_premiumService.isPremium) return true;
    return _remainingLives > 0;
  }
  
  Future<void> useLive() async {
    // Premium kullanıcıları için can azaltma
    if (_premiumService.isPremium) return;
    
    if (_remainingLives <= 0) return;
    
    _remainingLives--;
    await _saveLivesData();
    notifyListeners();
  }
  
  // Reklam izleme veya içerik satın alma ile can ekleme
  Future<void> addLives(int count) async {
    // Premium kullanıcıları için can eklemek gerekmez
    if (_premiumService.isPremium) return;
    
    if (count <= 0) return;
    
    // Maksimum can sayısını aşmayacak şekilde can ekle
    int newLives = _remainingLives + count;
    if (newLives > maxLives) newLives = maxLives;
    
    _remainingLives = newLives;
    await _saveLivesData();
    notifyListeners();
  }
  
  // Kart hakkı sistemi için metotlar
  Future<void> initCards() async {
    if (_prefs == null) await init();
    
    // Her zaman maksimum kart sayısı ile başla
    _remainingCards = maxCards;
    _lastCardsRefreshTime = DateTime.now();
    await _saveCardsData();
    
    // Timer'ı başlat
    _startCardsTimer();
  }
  
  void _startCardsTimer() {
    // Önceki timer varsa temizle
    _cardsTimer?.cancel();
    
    // Her dakika kontrol edecek timer başlat
    _cardsTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkCardsRefresh();
    });
  }
  
  void _checkCardsRefresh() {
    if (_lastCardsRefreshTime == null) return;
    
    final now = DateTime.now();
    final difference = now.difference(_lastCardsRefreshTime!);
    
    if (difference.inHours >= cardRefreshHours && _remainingCards < maxCards) {
      // Kaç kez refresh olacağını hesapla
      final refreshCount = difference.inHours ~/ cardRefreshHours;
      
      // Her refresh için maxCards kadar kart ekle ama maksimum kart sayısını geçme
      int newCards = _remainingCards + (refreshCount * maxCards);
      if (newCards > maxCards) newCards = maxCards;
      
      // Son refresh zamanını güncelle
      _lastCardsRefreshTime = _lastCardsRefreshTime!.add(
        Duration(hours: refreshCount * cardRefreshHours)
      );
      
      if (_remainingCards != newCards) {
        _remainingCards = newCards;
        _saveCardsData();
        notifyListeners();
      }
    }
  }
  
  Future<void> _saveCardsData() async {
    if (_prefs == null) return;
    
    await _prefs!.setInt('remaining_cards', _remainingCards);
    if (_lastCardsRefreshTime != null) {
      await _prefs!.setString('last_cards_refresh_time', _lastCardsRefreshTime!.toIso8601String());
    }
  }
  
  bool hasEnoughCards() {
    // Premium kullanıcıları için her zaman yeterli kart vardır
    if (_premiumService.isPremium) return true;
    return _remainingCards > 0;
  }
  
  Future<void> useCard() async {
    // Premium kullanıcıları için kart hakkı azaltma
    if (_premiumService.isPremium) return;
    
    if (_remainingCards <= 0) return;
    
    _remainingCards--;
    await _saveCardsData();
    notifyListeners();
  }
  
  // Reklam izleme veya içerik satın alma ile kart hakkı ekleme
  Future<void> addCards(int count) async {
    // Premium kullanıcıları için kart eklemek gerekmez
    if (_premiumService.isPremium) return;
    
    if (count <= 0) return;
    
    // Maksimum kart sayısını aşmayacak şekilde kart ekle
    int newCards = _remainingCards + count;
    if (newCards > maxCards) newCards = maxCards;
    
    _remainingCards = newCards;
    await _saveCardsData();
    notifyListeners();
  }

  Future<List<QuestionModel>> getMistakes({String level = 'MIX', String category = ''}) async {
    try {
      if (_prefs == null) {
        await init();
      }
      
      print('=== MISTAKES LOG BAŞLANGICI ===');
      print('getMistakes çağrıldı - Seviye: $level, Kategori: $category');
      
      // Yeni format ile hataları yükle
      List<Map<String, dynamic>> mistakesList = [];
      final savedMistakesJson = _prefs!.getString('practice_mistakes_data');
      if (savedMistakesJson != null) {
        final List<dynamic> loadedList = json.decode(savedMistakesJson);
        mistakesList = loadedList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('Yüklenen JSON veri: $savedMistakesJson');
      }
      
      // Eski format kontrolü - geriye dönük uyumluluk için
      if (mistakesList.isEmpty) {
        final savedMistakes = _prefs!.getStringList('practice_mistakes');
        if (savedMistakes == null || savedMistakes.isEmpty) {
          print('Hata listesi boş veya null. Boş liste döndürülüyor.');
          return [];
        }
        
        print('Eski format hata listesi bulundu fakat desteklenmiyor. Sayaçlar sıfırlanacak.');
        await _prefs!.setString('mistake_counts_by_level', '{}');
        _mistakeCountsByLevel = {};
        notifyListeners();
        print('=== RECALCULATE MISTAKES LOG SONU ===');
        return [];
      }
      
      print('Hatalar listesinde ${mistakesList.length} kelime bulundu');
      print('Tüm hatalar:');
      for (var i = 0; i < mistakesList.length; i++) {
        print('${i+1}. Kelime: ${mistakesList[i]['word']}, Seviye: ${mistakesList[i]['level']}, Kaynak: ${mistakesList[i]['source']}, Kategori: ${mistakesList[i]['category']}');
      }
      
      // Eğer kategori belirtilmişse, sadece o kategoriye ait hataları göster
      if (category.isNotEmpty && category != 'all') {
        String sourceFile = '';
        
        // Kategori adından kaynak dosya adını belirle
        switch (category) {
          case 'oxford_3000':
            sourceFile = 'The_Oxford_3000';
            break;
          case 'oxford_5000':
            sourceFile = 'The_Oxford_5000';
            break;
          case 'american_3000':
            sourceFile = 'American_Oxford_3000';
            break;
          case 'american_5000':
            sourceFile = 'American_Oxford_5000';
            break;
          default:
            // Kategori belirtilmişse ama eşleşme yoksa, işlem yapma
            break;
        }
        
        if (sourceFile.isNotEmpty) {
          // Sadece belirtilen kaynak dosyasından gelen hataları filtrele
          var beforeCount = mistakesList.length;
          mistakesList = mistakesList.where((item) => 
            item['source'] == sourceFile || 
            (item['category'] == category && item['source'] == 'unknown')
          ).toList();
          print('$category kategorisine göre filtrelendi. Önceki: $beforeCount, Sonraki: ${mistakesList.length}');
          print('Filtrelenen kelimeler:');
          for (var i = 0; i < mistakesList.length; i++) {
            print('${i+1}. Kelime: ${mistakesList[i]['word']}, Seviye: ${mistakesList[i]['level']}, Kaynak: ${mistakesList[i]['source']}');
          }
        }
      }
      
      // Belirli bir seviye seçilmişse, sadece o seviyedeki hataları filtrele
      if (level != 'MIX') {
        var beforeCount = mistakesList.length;
        mistakesList = mistakesList.where((item) => 
          item['level'].toString().toUpperCase() == level
        ).toList();
        print('Hatalı kelimeler seviye $level için filtrelendi. Önceki: $beforeCount, Sonraki: ${mistakesList.length}');
        print('Filtrelenen kelimeler:');
        for (var i = 0; i < mistakesList.length; i++) {
          print('${i+1}. Kelime: ${mistakesList[i]['word']}, Seviye: ${mistakesList[i]['level']}, Kaynak: ${mistakesList[i]['source']}');
        }
      }
      
      // Kelimeleri karıştır
      mistakesList.shuffle();
      
      if (mistakesList.isEmpty) {
        print('Filtreleme sonrası liste boş. Boş liste döndürülüyor.');
        return [];
      }
      
      // Kaydedilmiş hata verilerinden QuestionModel nesneleri oluştur
      List<QuestionModel> questions = [];
      
      for (var wordData in mistakesList) {
        // Eğer bir kelime için seçenekler oluşturmak istiyorsak ilgili JSON dosyasını yüklemeliyiz
        print('Kelime için seçenekler oluşturuluyor: ${wordData['word']}');
        final incorrectOptions = await _getRandomOptionsForMistake(wordData);
        if (incorrectOptions.isEmpty) {
          print('${wordData['word']} için seçenek oluşturulamadı, atlanıyor.');
          continue;
        }
        
        // Doğru cevabı ekle ve karıştır
        final List<String> allOptions = [...incorrectOptions, wordData['turkishMeaning'] as String];
        allOptions.shuffle();
        
        final correctIndex = allOptions.indexOf(wordData['turkishMeaning'] as String);
        
        questions.add(QuestionModel(
          word: wordData['word'] as String,
          partOfSpeech: wordData['partOfSpeech'] as String,
          level: wordData['level'] as String,
          audioUrl: wordData['audioUrl'] as String,
          englishMeaning: wordData['englishMeaning'] as String,
          turkishMeaning: wordData['turkishMeaning'] as String,
          pronunciation: wordData['pronunciation'] as String,
          examples: (wordData['examples'] as List).map((e) => ExampleModel(
            english: e['english'] as String,
            turkish: e['turkish'] as String,
          )).toList(),
          options: allOptions,
          correctOptionIndex: correctIndex,
        ));
        print('Soru oluşturuldu: ${wordData['word']} (${wordData['level']})');
      }
      
      print('Toplam ${questions.length} soru oluşturuldu.');
      print('=== MISTAKES LOG SONU ===');
      return questions;
    } catch (e, stackTrace) {
      print('Error loading mistakes: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
  
  // Yardımcı metod: Mistake için rastgele seçenekler bul
  Future<List<String>> _getRandomOptionsForMistake(Map<String, dynamic> wordData) async {
    try {
      String jsonFile;
      
      // Hatanın kaynağına göre doğru JSON dosyasını belirle
      final source = wordData['source'] as String? ?? 'The_Oxford_3000';
      jsonFile = 'assets/data/$source.json';
      
      print('${wordData['word']} için seçenekler oluşturuluyor. Kaynak dosya: $jsonFile');
      
      // JSON dosyasını yükle
      final ByteData data = await rootBundle.load(jsonFile);
      final jsonString = utf8.decode(data.buffer.asUint8List());
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      
      // Aynı kelime türüne sahip kelimeler arasından rastgele 4 tanesini seç
      final possibleOptions = jsonList
          .where((item) => 
            item is Map<String, dynamic> && 
            item['word'] != wordData['word'] && 
            item['type'] == wordData['partOfSpeech']
          )
          .map((item) => item['turkishMeaning'] as String)
          .toList();
      
      if (possibleOptions.length < 4) {
        print('${wordData['word']} için yetersiz seçenek: ${possibleOptions.length}');
        return [];
      }
      
      // Rastgele 4 yanlış seçenek seç
      possibleOptions.shuffle();
      final selectedOptions = possibleOptions.take(4).toList();
      print('${wordData['word']} için seçenekler: $selectedOptions');
      return selectedOptions;
    } catch (e, stackTrace) {
      print('Error getting random options for ${wordData['word']}: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // SharedPreferences erişimi sağlayan metot
  Future<SharedPreferences?> getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs;
  }

  Future<void> resetAllProgress() async {
    try {
      print('İlerlemeyi sıfırlama işlemi başlatılıyor...');
      
      // SharedPreferences örneğini güvenli bir şekilde al
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
        print('Mevcut SharedPreferences anahtarları: ${prefs.getKeys()}');
      } catch (e) {
        print('SharedPreferences alınırken hata: $e');
        throw Exception('Ayarlar depolaması başlatılamadı');
      }
      
      // 1. TÜM SharedPreferences verilerini tamamen sil (clear() metodu)
      try {
        await prefs.clear();
        print('TÜM SharedPreferences verileri tamamen silindi!');
        print('Silme sonrası kalan anahtarlar: ${prefs.getKeys()}');
      } catch (e) {
        print('SharedPreferences temizlenirken kritik hata: $e');
        rethrow;
      }
      
      // 2. Timer'ları iptal et
      _livesTimer?.cancel();
      _cardsTimer?.cancel();
      _livesTimer = null;
      _cardsTimer = null;
      
      // 3. Provider'ı başlangıç durumuna getir - Quiz ile ilgili tüm durumlar
      _questions = [];
      _userAnswers = [];
      _currentQuestionIndex = 0;
      _selectedAnswer = null;
      _isCompleted = false;
      _startTime = null;
      _lastResumeTime = null;
      _completionTime = null;
      _activeTime = Duration.zero;
      _currentCategory = null;
      _currentLevel = null;
      _currentExamNumber = null;
      
      // 4. Can ve kart sistemini sıfırla
      _remainingLives = maxLives;
      _lastLivesRefreshTime = DateTime.now();
      _remainingCards = maxCards;
      _lastCardsRefreshTime = DateTime.now();
      _currentScore = 0;
      
      // 5. Quiz durumlarını sıfırla - Sadece ilk seviyeleri aç
      _quizStatuses = {
        'ilkokul_1_unlocked': QuizStatus.notStarted,
        'ortaokul_1_unlocked': QuizStatus.notStarted,
        'lise_1_unlocked': QuizStatus.notStarted,
      };
      
      // 6. Word Bank, görülen kelimeler ve mistakes verilerini sıfırla
      // Belleğimizdeki listeleri temizle
      _viewedWords = [];
      _viewedWordIds = [];
      _practiceMistakes = [];
      _mistakeCountsByLevel = {};
      _directMistakes = []; // Doğrudan hataları da temizle
      
      // 7. İlk kez kayıt işlemlerini gerçekleştir (initial setup)
      try {
        // Başlangıç değerlerini kaydet
        await prefs.setInt('remaining_lives', maxLives);
        await prefs.setString('last_lives_refresh_time', DateTime.now().toIso8601String());
        await prefs.setInt('remaining_cards', maxCards);
        await prefs.setString('last_cards_refresh_time', DateTime.now().toIso8601String());
      
        // Quiz durumlarını kaydet
        final statusesMap = _quizStatuses.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        await prefs.setString('quiz_statuses', json.encode(statusesMap));
        
        // Açık olan seviyeleri kaydet
        final unlockedLevels = _quizStatuses.entries
            .where((entry) => entry.key.endsWith('_unlocked'))
            .map((entry) => entry.key)
            .toList();
        await prefs.setStringList('unlocked_levels', unlockedLevels);
        
        // Word Bank ve Mistakes listelerini sıfırla
        await prefs.setStringList('viewed_words', []);
        await prefs.setStringList('viewed_word_ids', []);
        await prefs.setStringList('practice_mistakes', []);
        await prefs.setString('practice_mistakes_data', '[]'); // Hata verilerini boş bir liste olarak ayarla
        await prefs.setString('mistake_counts_by_level', '{}');
        await prefs.setString('direct_mistakes_data', '[]'); // Doğrudan hataları da sıfırla
        await prefs.setInt('total_cards_seen', 0);
        await prefs.setInt('total_quizzes_completed', 0);
        
        print('İlk değerler başarıyla kaydedildi');
      } catch (e) {
          print('İlk değerler kaydedilirken hata: $e');
      }
 
      // 8. Can ve kart timer'larını yeniden başlat
      _startLivesTimer();
      _startCardsTimer();
      
      // 9. Değişiklikleri bildir
      notifyListeners();
      
      print('Tüm ilerleme başarıyla sıfırlandı');
      print('NOT: Bu işlemden sonra QuizProvider.init() metodu çağrılmalıdır');
      
      // _prefs değişkenini güncelle
      _prefs = prefs;
      
      return;
    } catch (e) {
      print('İlerleme sıfırlanırken kritik hata oluştu: $e');
      rethrow;
    }
  }

  // Tüm hatalı kelimeleri temizleyen metod
  Future<void> clearAllMistakes() async {
    try {
      if (_prefs == null) {
        await init();
      }
      
      print('=== CLEAR MISTAKES LOG BAŞLANGICI ===');
      // Mevcut hataları logla
      final savedMistakesJson = _prefs!.getString('practice_mistakes_data');
      if (savedMistakesJson != null) {
        final List<dynamic> loadedList = json.decode(savedMistakesJson);
        final mistakesList = loadedList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('Temizlenmeden önce ${mistakesList.length} hata vardı.');
        for (var i = 0; i < mistakesList.length; i++) {
          print('${i+1}. Kelime: ${mistakesList[i]['word']}, Seviye: ${mistakesList[i]['level']}, Kaynak: ${mistakesList[i]['source']}');
        }
      } else {
        print('Temizlenmeden önce hata listesi boş veya null.');
      }
      
      // Tüm hata verilerini temizle
      await _prefs!.setString('practice_mistakes_data', '[]');
      await _prefs!.setStringList('practice_mistakes', []);
      await _prefs!.setString('mistake_counts_by_level', '{}');
      
      // Bellek verileri de temizle
      _practiceMistakes = [];
      _mistakeCountsByLevel = {};
      
      print('Tüm hatalar başarıyla temizlendi.');
      print('=== CLEAR MISTAKES LOG SONU ===');
      notifyListeners();
      
    } catch (e, stackTrace) {
      print('Hatalar temizlenirken hata oluştu: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Özel bir soru listesini yükler (doğrudan hatalar listesi için)
  Future<void> loadCustomQuestions(List<QuestionModel> customQuestions, {String category = ''}) async {
    try {
      print('Özel soru listesi yükleniyor. Soru sayısı: ${customQuestions.length}');
      
      // Mevcut soruları temizle
      _questions = [];
      
      // Özel soruları ekle
      _questions.addAll(customQuestions);
      
      // Kategori bilgisini kaydet
      if (category.isNotEmpty) {
        _currentCategory = category;
        print('Özel quiz kategorisi ayarlandı: $_currentCategory');
      }
      
      // Kullanıcı cevaplarını sıfırla
      _userAnswers = List.filled(_questions.length, null);
      _currentQuestionIndex = 0;
      _selectedAnswer = null;
      _isCompleted = false;
      
      // Zamanlayıcıyı başlat
      _startTime = DateTime.now();
      _lastResumeTime = DateTime.now();
      _activeTime = Duration.zero;
      
      print('Özel soru listesi başarıyla yüklendi. Toplam soru: ${_questions.length}');
      
      // Bildirim gönder
      notifyListeners();
    } catch (e) {
      print('Özel soru listesi yüklenirken hata oluştu: $e');
      rethrow;
    }
  }
} 
