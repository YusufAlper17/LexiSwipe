import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/word_model.dart';
import '../../../services/word_bank_service.dart';
import '../../../services/text_to_speech_service.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_snackbar.dart';

class WordBankPage extends StatefulWidget {
  const WordBankPage({Key? key}) : super(key: key);

  @override
  State<WordBankPage> createState() => _WordBankPageState();
}

class _WordBankPageState extends State<WordBankPage> with SingleTickerProviderStateMixin {
  final WordBankService _wordBankService = WordBankService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  List<WordModel> _allWords = [];
  List<WordModel> _filteredWords = [];
  bool _isLoading = true;
  
  // Seviye filtresi için değişkenler
  String _selectedLevel = 'MIX';
  final List<String> _levels = ['MIX', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  bool _isFilterPanelOpen = false;
  
  // Kaydırma ve çevirme için değişkenler
  bool isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  double _dragOffset = 0;
  double _dragAngle = 0;
  int _keptWordsCount = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadWords();
  }

  void _setupAnimations() {
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _flipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _flipAnimation.addListener(() {
      setState(() {});
    });
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    
    if (_flipController.value == 0) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
    });

    final words = await _wordBankService.loadWordBank();
    
    setState(() {
      _allWords = words;
      _filterWordsByLevel();
      _isLoading = false;
    });
  }

  void _filterWordsByLevel() {
    if (_selectedLevel == 'MIX') {
      _filteredWords = List.from(_allWords);
    } else {
      _filteredWords = _allWords
          .where((word) => word.level.toUpperCase() == _selectedLevel)
          .toList();
    }
  }

  void _changeLevel(String level) {
    setState(() {
      _selectedLevel = level;
      _filterWordsByLevel();
      
      // Flip kartı ters çevrildiyse düz pozisyona getir
      if (isFlipped) {
        _flipController.value = 0;
        isFlipped = false;
      }
      
      // Drag offset'i sıfırla
      _dragOffset = 0;
      _dragAngle = 0;
    });
  }

  Future<void> _removeWord(String wordId) async {
    final success = await _wordBankService.removeWordFromBank(wordId);
    if (success) {
      setState(() {
        _allWords.removeWhere((word) => word.id == wordId);
        _filterWordsByLevel();
      });
    }
  }

  void _onDismissed(DismissDirection direction, WordModel word) {
    if (direction == DismissDirection.startToEnd) {
      // Sağa kaydırma - kelimeyi kaldır
      _removeWord(word.id);
      setState(() {
        _filteredWords.remove(word);
        if (isFlipped) {
          _flipController.value = 0;
          isFlipped = false;
        }
      });
    } else {
      // Sola kaydırma - kelimeyi tut
      setState(() {
        // Sadece kelimeyi listenin en sonuna taşıyarak
        // görsel olarak yeni kelimeye geçiyormuş gibi göster
        if (_filteredWords.isNotEmpty) {
          final currentWord = _filteredWords.removeAt(0);
          _filteredWords.add(currentWord);
          _keptWordsCount++;
        }
        if (isFlipped) {
          _flipController.value = 0;
          isFlipped = false;
        }
      });
    }
  }

  Future<void> _showResetConfirmationDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final String levelText = _selectedLevel == 'MIX' 
            ? 'tüm seviyelerdeki kelimeleri'
            : '$_selectedLevel seviyesindeki kelimeleri';
            
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Kelimeleri Temizle',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Kelime bankasından $levelText kaldırmak istediğinize emin misiniz? Bu işlem geri alınamaz.',
            style: GoogleFonts.poppins(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'İptal',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await _wordBankService.clearWordsByLevel(_selectedLevel);
                if (success) {
                  setState(() {
                    if (_selectedLevel == 'MIX') {
                      _allWords.clear();
                      _filteredWords.clear();
                    } else {
                      _allWords.removeWhere((word) => word.level.toUpperCase() == _selectedLevel);
                      _filterWordsByLevel();
                    }
                  });
                  if (context.mounted) {
                    CustomSnackbar.showSuccess(
                      context,
                      '$_selectedLevel seviyesindeki kelimeler başarıyla temizlendi'
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Temizle',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  Future<void> _playWordAudio(WordModel word) async {
    try {
      await _ttsService.speakWord(word.word, audioUrl: word.audioUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses oynatılamadı.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seviye başına kelime sayılarını hesapla
    final Map<String, int> levelCounts = {
      for (var level in _levels)
        level: level == 'MIX'
            ? _allWords.length
            : _allWords.where((word) => word.level.toUpperCase() == level).length
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Word Bank',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Filtre butonu
          PopupMenuButton<String>(
            initialValue: _selectedLevel,
            onSelected: (String level) {
              _changeLevel(level);
            },
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            color: Colors.white,
            offset: const Offset(0, 8),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(_selectedLevel).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedLevel,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            itemBuilder: (BuildContext context) {
              return _levels.map((String level) {
                final isSelected = level == _selectedLevel;
                final wordCount = levelCounts[level] ?? 0;
                
                return PopupMenuItem<String>(
                  value: level,
                  height: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getLevelColor(level).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: _getLevelColor(level),
                                  size: 18,
                                )
                              : Text(
                                  level[0],
                                  style: GoogleFonts.poppins(
                                    color: _getLevelColor(level),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                level,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? _getLevelColor(level) : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getLevelColor(level).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$wordCount kelime',
                                  style: GoogleFonts.poppins(
                                    color: _getLevelColor(level),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList();
            },
          ),
          if (_allWords.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showResetConfirmationDialog,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Kelime Bankasını Temizle',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2C3E50),
              const Color(0xFF34495E),
            ],
          ),
        ),
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _allWords.isEmpty
              ? _buildEmptyState()
              : SafeArea(
                  child: Column(
                    children: [
                      _filteredWords.isEmpty
                          ? _buildNoWordsForLevel()
                          : Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.center,
                                children: [
                                  // Arka plan kartları
                                  ...List.generate(
                                    math.min(3, _filteredWords.length),
                                    (index) => Positioned.fill(
                                      child: Center(
                                        child: Transform(
                                          transform: Matrix4.identity()
                                            ..setEntry(3, 2, 0.001)
                                            ..translate(0.0, index * 8.0, 0.0),
                                          alignment: Alignment.center,
                                          child: Opacity(
                                            opacity: 1 - (index * 0.15),
                                            child: Container(
                                              width: MediaQuery.of(context).size.width * 0.85,
                                              height: MediaQuery.of(context).size.width * 1.2,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(28),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 20,
                                                    spreadRadius: 0,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ).reversed,
                                  // Aktif kart
                                  if (_filteredWords.isNotEmpty)
                                    Positioned.fill(
                                      child: Center(
                                        child: GestureDetector(
                                          onHorizontalDragUpdate: (details) {
                                            setState(() {
                                              final newOffset = _dragOffset + details.delta.dx;
                                              if (newOffset.abs() <= MediaQuery.of(context).size.width * 0.8) {
                                                _dragOffset = newOffset;
                                                _dragAngle = (_dragOffset / 1000) * math.pi / 6;
                                              }
                                            });
                                          },
                                          onHorizontalDragEnd: (details) {
                                            if (_dragOffset.abs() > 100) {
                                              final direction = _dragOffset > 0 
                                                  ? DismissDirection.startToEnd 
                                                  : DismissDirection.endToStart;
                                              _onDismissed(direction, _filteredWords[0]);
                                            }
                                            setState(() {
                                              _dragOffset = 0;
                                              _dragAngle = 0;
                                            });
                                          },
                                          child: Transform(
                                            transform: Matrix4.identity()
                                              ..setEntry(3, 2, 0.001)
                                              ..translate(_dragOffset)
                                              ..rotateZ(_dragAngle),
                                            alignment: Alignment.center,
                                            child: Transform(
                                              transform: Matrix4.identity()
                                                ..setEntry(3, 2, 0.001)
                                                ..rotateY(math.pi * _flipAnimation.value),
                                              alignment: Alignment.center,
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.85,
                                                height: MediaQuery.of(context).size.width * 1.2,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(28),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 20,
                                                      spreadRadius: 0,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: GestureDetector(
                                                  onTap: _flipCard,
                                                  child: _flipAnimation.value < 0.5
                                                      ? _buildFrontCard(_filteredWords[0])
                                                      : Transform(
                                                          transform: Matrix4.identity()..rotateY(math.pi),
                                                          alignment: Alignment.center,
                                                          child: _buildBackCard(_filteredWords[0]),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: SafeArea(
                          bottom: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.white.withOpacity(0.8),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ).createShader(bounds);
                                      },
                                      child: const Icon(
                                        Icons.auto_stories,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.white.withOpacity(0.9),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ).createShader(bounds);
                                      },
                                      child: Text(
                                        '${_filteredWords.length} kelime',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildNoWordsForLevel() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$_selectedLevel Seviyesinde Kelime Bulunamadı',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lütfen başka bir seviye seçin',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.library_books_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Kelime Bankası Boş',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz kelime eklemesi yapmadınız',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(WordModel word) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8F9FE),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getLevelColor(word.level).withOpacity(0.15),
                      _getLevelColor(word.level).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getLevelColor(word.level).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  word.level,
                  style: GoogleFonts.poppins(
                    color: _getLevelColor(word.level).withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.volume_up, size: 24, color: const Color(0xFF4285F4)),
                  onPressed: () => _playWordAudio(word),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            word.word,
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1F36),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            word.pronunciation,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: const Color(0xFF4F566B),
              fontStyle: FontStyle.normal,
              height: 1.5,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8F0FE),
                    const Color(0xFFF0E7FE),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4E3FC),
                  width: 1,
                ),
              ),
              child: Text(
                word.type,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF4285F4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Kelimeyi görmek için dokun',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF8792A2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(WordModel word) {
    final Color primaryBlue = Color(0xFF2D3B55);
    final Color secondaryBlue = Color(0xFF4A6FA5);
    final Color subtleText = Color(0xFF64748B);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Anlamlar Bölümü
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
            if (word.examples.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(thickness: 1),
              ),
              // Örnekler Bölümü
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
            const SizedBox(height: 20),
            Center(
              child: Text(
                'geri dönmek için dokun',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: subtleText,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
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
      case 'MIX':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
} 