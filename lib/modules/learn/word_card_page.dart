import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../services/text_to_speech_service.dart';
import '../../models/word_model.dart';
import '../../services/word_bank_service.dart';
import 'word_bank/word_bank_sheet.dart';
import 'package:provider/provider.dart';
import '../../modules/quiz/quiz_provider.dart';
import '../../services/sound_service.dart';
import '../../services/ad_service.dart';
import '../../modules/level/level_selection_page.dart';

class WordCardPage extends StatefulWidget {
  final List<dynamic>? words;
  final String? level;
  final String? wordListType;
  
  const WordCardPage({
    Key? key,
    this.words,
    this.level,
    this.wordListType,
  }) : super(key: key);

  @override
  State<WordCardPage> createState() => _WordCardPageState();
}

class _WordCardPageState extends State<WordCardPage> with SingleTickerProviderStateMixin {
  late List<WordModel> words;
  late List<WordModel> remainingWords;
  final WordBankService _wordBankService = WordBankService();
  final List<WordModel> sessionWordBank = [];
  int learnedWordsCount = 0;
  int sessionWordBankCount = 0;
  bool isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late Animation<double> _swipeAnimation;
  late Animation<double> _scaleAnimation;
  bool isLoading = true;
  double _dragOffset = 0;
  double _dragAngle = 0;
  
  // Oturum için görüntülenen kelimeleri takip etmek için yeni set
  final Set<String> _seenWordsInSession = {};
  final SoundService _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadWords();
    sessionWordBankCount = 0;
  }

  Future<void> _loadWords() async {
    try {
      String jsonFileName;
      switch (widget.wordListType) {
        case 'oxford_3000':
          jsonFileName = 'The_Oxford_3000.json';
          break;
        case 'oxford_5000':
          jsonFileName = 'The_Oxford_5000.json';
          break;
        case 'american_3000':
          jsonFileName = 'American_Oxford_3000.json';
          break;
        case 'american_5000':
          jsonFileName = 'American_Oxford_5000.json';
          break;
        default:
          jsonFileName = 'words.json';
      }

      print('Loading words from assets/data/$jsonFileName');
      final String jsonString = await rootBundle.loadString('assets/data/$jsonFileName');
      print('JSON string loaded, length: ${jsonString.length}');
      
      final List<dynamic> wordsList = json.decode(jsonString);
      print('JSON decoded successfully');
      print('Found ${wordsList.length} words in total');
      
      setState(() {
        words = wordsList.map((word) => WordModel.fromJson(word)).toList();
        print('Converted all words to WordModel');
        
        if (widget.level != null && widget.level?.toLowerCase() != 'mix') {
          print('Filtering words for level: ${widget.level}');
          words = words.where((word) => word.level.toLowerCase() == widget.level?.toLowerCase()).toList();
          print('Found ${words.length} words for level ${widget.level}');
          
          if (words.isEmpty) {
            print('Warning: No words found for level ${widget.level}');
            setState(() {
              words = [];
              remainingWords = [];
              isLoading = false;
            });
            return;
          }
        }
        
        // Bu oturumda görülmemiş kelimeleri filtrele
        words = words.where((word) => !_seenWordsInSession.contains(word.id.toString())).toList();
        
        remainingWords = List.from(words);
        print('Remaining words initialized with ${remainingWords.length} words');
        remainingWords.shuffle();
        isLoading = false;
        
        // Sayaçları sıfırla
        learnedWordsCount = 0;
      });
    } catch (e, stackTrace) {
      print('Error loading words: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        words = [];
        remainingWords = [];
        isLoading = false;
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hata'),
            content: Text('Kelimeler yüklenirken bir hata oluştu: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    }
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

    _swipeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.8,
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
      _soundService.playFlipSound();
    } else {
      _flipController.reverse();
      _soundService.playFlipSound();
    }
    
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  void _onDismissed(DismissDirection direction, WordModel word) {
    // Kart hakkını al ve azalt
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizProvider.useCard();
    
    setState(() {
      remainingWords.remove(word);
      if (direction == DismissDirection.endToStart) {
        _wordBankService.addWordToSessionBank(word, sessionWordBank);
        _wordBankService.addWordToBank(word);
        sessionWordBankCount++;
        _soundService.playSwipeLeftSound();
      } else {
        learnedWordsCount++;
        _soundService.playSwipeRightSound();
      }
      // Kelimeyi görülenler listesine ekle
      _seenWordsInSession.add(word.id.toString());
      
      if (isFlipped) {
        _flipController.value = 0;
        isFlipped = false;
      }
      
      // Kart hakkı kalmadıysa popup göster ve ana sayfaya dön
      if (quizProvider.remainingCards <= 0) {
        _showNoCardsDialog();
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2C3E50),
                const Color(0xFF34495E),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (words.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2C3E50),
                const Color(0xFF34495E),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '${widget.level} Seviyesi İçin Kelime Bulunamadı',
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
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Geri Dön',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Level ${widget.level ?? ""} - ${widget.wordListType ?? ""}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.library_books, color: Colors.white, size: 20),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.7,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      builder: (context, scrollController) => WordBankSheet(
                        words: sessionWordBank,
                        scrollController: scrollController,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E50),
              const Color(0xFF34495E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(
                      math.min(3, remainingWords.length),
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
                    if (remainingWords.isNotEmpty)
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
                              if (_dragOffset.abs() > 70) {
                                final direction = _dragOffset > 0 
                                    ? DismissDirection.startToEnd 
                                    : DismissDirection.endToStart;
                                _onDismissed(direction, remainingWords[0]);
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
                                        ? _buildFrontCard(remainingWords[0])
                                        : Transform(
                                            transform: Matrix4.identity()..rotateY(math.pi),
                                            alignment: Alignment.center,
                                            child: _buildBackCard(remainingWords[0]),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProgressIndicator(
                          sessionWordBankCount.toString(),
                          Icons.library_books,
                        ),
                        const SizedBox(width: 16),
                        _buildProgressIndicator(
                          learnedWordsCount.toString(),
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
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
                  onPressed: () => _playAudio(word.audioUrl),
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
              'Tap to flip',
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
            // Meanings Section
            Text(
              'MEANINGS',
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
            // Examples Section
            Text(
              'EXAMPLES',
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
            const SizedBox(height: 20),
            Center(
              child: Text(
                'tap to flip back',
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
      default:
        return Colors.grey;
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      final ttsService = TextToSpeechService();
      await ttsService.speakWord(remainingWords[0].word, audioUrl: audioUrl);
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

  void _showNoCardsDialog() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final timeUntilNextCard = quizProvider.timeUntilNextCard;
    
    final String timeText = timeUntilNextCard.inHours > 0
        ? '${timeUntilNextCard.inHours} saat ${timeUntilNextCard.inMinutes % 60} dakika'
        : '${timeUntilNextCard.inMinutes} dakika';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2C3E50).withOpacity(0.5), const Color(0xFF34495E).withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.credit_card,
                    size: 48,
                    color: Colors.blue.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Kart Hakkınız Bitti',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Şu anda yeterli kart hakkınız bulunmuyor. Her ${QuizProvider.cardRefreshHours} saatte ${QuizProvider.maxCards} kart hakkı yenilenir.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sonraki Kart Destesine',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            timeText,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showWatchCardAdDialog(context);
                },
                icon: const Icon(Icons.play_circle_filled, size: 20),
                label: const Text('Video İzle (+25 Kart)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LevelSelectionPage(category: 'learn'),
                    ),
                    (route) => false,
                  );
                },
                
                
                
                
              
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: Text(
                  'Daha Sonra',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Video reklamı izleyerek kart kazanma diyaloğu
  void _showWatchCardAdDialog(BuildContext context) {
    // QuizProvider'ı diyaloğa girmeden önce al
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade100, Colors.blue.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_fill,
                    size: 48,
                    color: Colors.blue.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Video İzle',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.credit_card,
                        color: Colors.amber.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '25 Kart Kazan',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Kısa bir video izleyerek kelime kartı hakkı kazanın',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        
                        // İlk önce ödül reklamını yükle ve göster
                        final bool adShown = await AdService.showRewardedAd(
                          onRewarded: () {
                            // Ödülü sadece reklam tamamlandığında ver
                            quizProvider.addCards(25); // 25 kart ekle
                            // Dialog'u göster
                            if (mounted) {
                              _showCardsEarnedDialog();
                            }
                          }
                        );
                        
                        // Reklam gösterilemezse kullanıcıya bildir
                        if (!adShown && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reklam gösterilemiyor. Lütfen daha sonra tekrar deneyin.'),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'İzle',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardsEarnedDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade300,
                            Colors.teal.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade200.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Başlık
              Text(
                '25 Kart Kazandınız!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Açıklama
              Text(
                'Tebrikler! 25 yeni kart hakkına sahip oldunuz. Kelime öğrenmeye devam edebilirsiniz.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Buton
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade500,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Harika!',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 