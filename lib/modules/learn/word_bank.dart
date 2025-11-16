import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kelime modeli
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
}

class Example {
  final String english;
  final String turkish;

  Example({required this.english, required this.turkish});

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      english: json['english']?.toString() ?? '',
      turkish: json['turkish']?.toString() ?? '',
    );
  }
}

// Kelime Bankası Servisi
class WordBankService {
  static const String _wordBankKey = 'word_bank';
  final List<WordModel> _wordBank = [];

  // Kelime bankasını yükle
  Future<List<WordModel>> loadWordBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? wordBankJson = prefs.getString(_wordBankKey);
      
      if (wordBankJson != null) {
        final List<dynamic> wordBankList = json.decode(wordBankJson);
        _wordBank.clear();
        _wordBank.addAll(
          wordBankList.map((word) => WordModel.fromJson(word)).toList()
        );
      }
      return _wordBank;
    } catch (e) {
      print('Kelime bankası yüklenirken hata: $e');
      return [];
    }
  }

  // Kelime bankasını kaydet
  Future<bool> saveWordBank(List<WordModel> wordBank) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String wordBankJson = json.encode(
        wordBank.map((word) => word.toJson()).toList()
      );
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
      return await saveWordBank(_wordBank);
    } catch (e) {
      print('Kelime bankasına kelime eklerken hata: $e');
      return false;
    }
  }

  // Kelime bankasından kelime çıkar
  Future<bool> removeWordFromBank(String wordId) async {
    try {
      _wordBank.removeWhere((word) => word.id == wordId);
      return await saveWordBank(_wordBank);
    } catch (e) {
      print('Kelime bankasından kelime çıkarırken hata: $e');
      return false;
    }
  }

  // Kelime bankasını temizle
  Future<bool> clearWordBank() async {
    try {
      _wordBank.clear();
      return await saveWordBank(_wordBank);
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
}

// Kelime Bankası Görünümü
class WordBankSheet extends StatelessWidget {
  final List<WordModel> words;
  final ScrollController scrollController;
  final Function(WordModel)? onWordTap;

  const WordBankSheet({
    Key? key,
    required this.words,
    required this.scrollController,
    this.onWordTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kelime Bankası',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1F36),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.indigo.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  colors: [
                                    const Color(0xFF2C3E50),
                                    const Color(0xFF34495E),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: const Icon(
                                Icons.auto_stories,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${words.length} kelime',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: words.isEmpty
                ? _buildEmptyState(context)
                : _buildWordList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_books_outlined,
              size: 48,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Kelime Bankası Boş',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu oturumda henüz kelime eklemediniz',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF8792A2),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4285F4),
                  width: 1,
                ),
              ),
              child: Text(
                'Kelime Eklemeye Başla',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF4285F4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList() {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEEF0F6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                if (onWordTap != null) {
                  onWordTap!(word);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.word,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1F36),
                              ),
                            ),
                            Container(
                              height: 1.5,
                              width: 60,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2563EB),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            word.type,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2563EB),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      word.turkishMeaning,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF4F566B),
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Kelime Bankası Sayfası
class WordBankPage extends StatefulWidget {
  const WordBankPage({Key? key}) : super(key: key);

  @override
  State<WordBankPage> createState() => _WordBankPageState();
}

class _WordBankPageState extends State<WordBankPage> {
  final WordBankService _wordBankService = WordBankService();
  List<WordModel> _words = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
    });

    final words = await _wordBankService.loadWordBank();
    
    setState(() {
      _words = words;
      _isLoading = false;
    });
  }

  Future<void> _removeWord(String wordId) async {
    final success = await _wordBankService.removeWordFromBank(wordId);
    if (success) {
      setState(() {
        _words.removeWhere((word) => word.id == wordId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Kelime Bankam',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A1F36),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1F36),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_words.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Color(0xFF1A1F36),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Kelime Bankasını Temizle',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'Tüm kelimeleri kelime bankasından kaldırmak istediğinize emin misiniz?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'İptal',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final success = await _wordBankService.clearWordBank();
                          if (success) {
                            setState(() {
                              _words.clear();
                            });
                          }
                        },
                        child: Text(
                          'Temizle',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.library_books_outlined,
                          size: 48,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Kelime Bankası Boş',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Henüz kelime eklemesi yapmadınız',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF8792A2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    final word = _words[index];
                    return Dismissible(
                      key: Key(word.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (direction) {
                        _removeWord(word.id);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFEEF0F6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {
                              // Kelime detaylarını göster
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => _buildWordDetailSheet(context, word),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            word.word,
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1A1F36),
                                            ),
                                          ),
                                          Container(
                                            height: 1.5,
                                            width: 60,
                                            margin: const EdgeInsets.only(top: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE2E8F0).withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getLevelColor(word.level).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getLevelColor(word.level).withOpacity(0.5),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              word.level,
                                              style: GoogleFonts.poppins(
                                                color: _getLevelColor(word.level),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF2563EB),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              word.type,
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF2563EB),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    word.turkishMeaning,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: const Color(0xFF4F566B),
                                      height: 1.4,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildWordDetailSheet(BuildContext context, WordModel word) {
    final Color primaryBlue = Color(0xFF2D3B55);
    final Color secondaryBlue = Color(0xFF4A6FA5);
    final Color subtleText = Color(0xFF64748B);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          word.word,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up,
                            color: Color(0xFF4285F4),
                          ),
                          onPressed: () {
                            // Ses çalma işlevi burada uygulanacak
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.pronunciation,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: subtleText,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(word.level).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getLevelColor(word.level).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            word.level,
                            style: GoogleFonts.poppins(
                              color: _getLevelColor(word.level),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2563EB),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            word.type,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2563EB),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(thickness: 1),
                    ),
                    Text(
                      'ANLAMLAR',
                      style: GoogleFonts.poppins(
                        color: subtleText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      word.englishMeaning,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: primaryBlue,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      word.turkishMeaning,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: secondaryBlue,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(thickness: 1),
                    ),
                    Text(
                      'ÖRNEKLER',
                      style: GoogleFonts.poppins(
                        color: subtleText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...word.examples.map((example) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            example.english,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              color: primaryBlue,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            example.turkish,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: secondaryBlue,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'A1':
        return Colors.green;
      case 'A2':
        return Colors.blue;
      case 'B1':
        return Colors.purple;
      case 'B2':
        return Colors.orange;
      case 'C1':
        return Colors.red;
      case 'C2':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
} 