import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../services/sound_service.dart';
import '../../services/ad_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/word_card_dialog.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'quiz_provider.dart';
import '../../widgets/hearts_indicator.dart';
import '../../widgets/score_indicator.dart';
import 'models/question_model.dart';
import 'package:audioplayers/audioplayers.dart';
import '../level/level_selection_page.dart';

class QuizPage extends StatefulWidget {
  final String category;
  final String level;
  final int examNumber;
  final List<QuestionModel>? questions;
  final bool isCustomQuiz;

  const QuizPage({
    super.key,
    required this.category,
    required this.level,
    required this.examNumber,
    this.questions,
    this.isCustomQuiz = false,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  late AnimationController _explanationController;
  late Animation<double> _explanationAnimation;
  late Animation<double> _explanationSlideAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SoundService _soundService = SoundService();
  bool _isLoading = true;
  String? _error;
  bool _isQuizStarted = true;
  bool _isQuizCompleted = false;

  @override
  void initState() {
    super.initState();
    _explanationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _explanationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _explanationController,
      curve: Curves.easeOutBack,
    ));
    _explanationSlideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _explanationController,
      curve: Curves.easeOutBack,
    ));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final quizProvider = context.read<QuizProvider>();
      quizProvider.resumeTimer();
      
      if (widget.isCustomQuiz && widget.questions != null) {
        print('Özel quiz yükleniyor. Soru sayısı: ${widget.questions!.length}');
        print('Özel quiz seviyesi: ${widget.level}');
        print('Özel quiz kategorisi: ${widget.category}');
        await quizProvider.loadCustomQuestions(
          widget.questions!,
          category: widget.category,
        );
      } else {
        print('Normal quiz yükleniyor. Kategori: ${widget.category}, Seviye: ${widget.level}, Sınav No: ${widget.examNumber}');
        await quizProvider.loadQuestions(
          widget.category,
          widget.level,
          widget.examNumber,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (quizProvider.isCompleted) {
          setState(() {
            _isQuizCompleted = true;
          });
        }
      }
    } catch (e) {
      print('Quiz yüklenirken hata oluştu: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
    
    if (mounted) {
      AdService.loadInterstitialAd();
    }
  }

  @override
  void dispose() {
    _explanationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String soundPath) async {
    try {
      switch (soundPath) {
        case 'sounds/mixkit-cool-interface-click-tone-2568.wav':
          await _soundService.playClickSound();
          break;
        case 'sounds/mixkit-correct-answer-tone-2870.wav':
          await _soundService.playCorrectSound();
          break;
        case 'sounds/error-8-206492.mp3':
          await _soundService.playWrongSound();
          break;
        default:
          await _audioPlayer.play(AssetSource(soundPath));
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _showExplanation() {
    _explanationController.forward(from: 0.0);
  }

  void _showWordCard(BuildContext context, QuestionModel question) {
    showDialog(
      context: context,
      builder: (context) => WordCardDialog(question: question),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
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

    if (_isQuizCompleted) {
      return _buildCompletionScreen();
    }

    if (_error != null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Geri Dön',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        final currentQuestion = quizProvider.currentQuestion;
        if (currentQuestion == null) return const SizedBox();

        return Scaffold(
          body: WillPopScope(
            onWillPop: () async {
              final quizId = '${widget.category}_${widget.level}_${widget.examNumber}';
              if (quizProvider.getQuizStatus(quizId) != QuizStatus.completed) {
                quizProvider.setQuizStatus(quizId, QuizStatus.inProgress);
                quizProvider.pauseTimer();
                await quizProvider.saveInProgressQuiz(quizId);
              }
              return true;
            },
            child: Container(
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
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
                          Row(
                            children: [
                              ScoreIndicator(
                                score: quizProvider.currentScore,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              HeartsIndicator(
                                totalHearts: QuizProvider.maxLives,
                                remainingHearts: quizProvider.remainingLives,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          currentQuestion.partOfSpeech,
                                          style: TextStyle(
                                            color: Colors.deepPurple.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _showWordCard(context, currentQuestion),
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.credit_card,
                                            color: Colors.blue.shade700,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    currentQuestion.word,
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple.shade900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Choose the correct Turkish meaning',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ...List.generate(
                              currentQuestion.options.length,
                              (index) => _buildOptionButton(
                                context: context,
                                text: currentQuestion.options[index],
                                index: index,
                                question: currentQuestion,
                                quizProvider: quizProvider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: quizProvider.currentQuestionIndex > 0
                                ? () => quizProvider.previousQuestion()
                                : null,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: quizProvider.currentQuestionIndex > 0
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: quizProvider.currentQuestionIndex > 0
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                          IconButton(
                            onPressed: () {
                              final lastVisitedIndex = quizProvider.getLastVisitedQuestionIndex();
                              if (quizProvider.currentQuestionIndex < lastVisitedIndex) {
                                quizProvider.nextQuestion();
                              }
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: quizProvider.currentQuestionIndex < quizProvider.getLastVisitedQuestionIndex()
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: quizProvider.currentQuestionIndex < quizProvider.getLastVisitedQuestionIndex()
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.1),
                                size: 24,
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
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String text,
    required int index,
    required QuestionModel question,
    required QuizProvider quizProvider,
  }) {
    final isSelected = quizProvider.userAnswers[quizProvider.currentQuestionIndex] == index;
    final isPreSelected = quizProvider.selectedAnswer == index;
    final isCorrect = index == question.correctOptionIndex;
    final showCorrectAnswer = quizProvider.userAnswers[quizProvider.currentQuestionIndex] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showCorrectAnswer
              ? null
              : () {
                  quizProvider.selectAnswer(index);
                  if (quizProvider.userAnswers[quizProvider.currentQuestionIndex] != null) {
                    _showExplanation();
                    final isCorrect = index == question.correctOptionIndex;
                    _playSound(isCorrect
                        ? 'sounds/mixkit-correct-answer-tone-2870.wav'
                        : 'sounds/error-8-206492.mp3');
                    
                    // Yanlış cevap verildiğinde ve can hakkı kalmadığında 1 saniye sonra popup göster
                    if (!isCorrect && quizProvider.remainingLives <= 0) {
                      Future.delayed(
                        const Duration(seconds: 1),
                        () {
                          if (mounted) {
                            _showNoLivesDialog();
                          }
                        },
                      );
                      return;
                    }
                    
                    Future.delayed(
                      Duration(milliseconds: isCorrect ? 1500 : 1750),
                      () {
                        if (!mounted) return;
                        
                        if (quizProvider.currentQuestionIndex < quizProvider.questions.length - 1) {
                          quizProvider.nextQuestion();
                        } else {
                          quizProvider.completeQuiz();
                          
                          setState(() {
                            _isQuizCompleted = true;
                          });
                        }
                      },
                    );
                  } else {
                    _playSound('sounds/mixkit-cool-interface-click-tone-2568.wav');
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getOptionBackgroundColor(isSelected, isPreSelected, isCorrect, showCorrectAnswer),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getOptionBorderColor(isSelected, isPreSelected, isCorrect, showCorrectAnswer),
                width: 2,
              ),
              boxShadow: [
                if (isSelected || isPreSelected)
                  BoxShadow(
                    color: _getOptionShadowColor(isSelected, isPreSelected, isCorrect, showCorrectAnswer),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                if (showCorrectAnswer && isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getOptionBackgroundColor(bool isSelected, bool isPreSelected, bool isCorrect, bool showCorrectAnswer) {
    if (showCorrectAnswer) {
      if (isCorrect) {
        return const Color(0xFFB7DFB9);
      } else if (isSelected && !isCorrect) {
        return Colors.red.shade50;
      }
      return Colors.white;
    }

    if (isPreSelected) {
      return Colors.blue.shade100;
    }

    if (isSelected) {
      return Colors.blue.shade50;
    }

    return Colors.white;
  }

  Color _getOptionBorderColor(bool isSelected, bool isPreSelected, bool isCorrect, bool showCorrectAnswer) {
    if (showCorrectAnswer) {
      if (isCorrect) {
        return const Color(0xFF1B5E20);
      } else if (isSelected && !isCorrect) {
        return Colors.red.shade600;
      }
      return Colors.grey.shade300;
    }

    if (isPreSelected) {
      return Colors.blue.shade600;
    }

    if (isSelected) {
      return Colors.blue.shade400;
    }

    return Colors.grey.shade300;
  }

  Color _getOptionShadowColor(bool isSelected, bool isPreSelected, bool isCorrect, bool showCorrectAnswer) {
    if (showCorrectAnswer) {
      if (isCorrect) {
        return Colors.green.withOpacity(0.2);
      } else if (isSelected && !isCorrect) {
        return Colors.red.withOpacity(0.2);
      }
    }

    if (isPreSelected || isSelected) {
      return Colors.blue.withOpacity(0.2);
    }

    return Colors.transparent;
  }

  void _showNoLivesDialog() {
    final QuizProvider quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final timeUntilNextLife = quizProvider.timeUntilNextLife;
    
    final String timeText = timeUntilNextLife.inHours > 0
        ? '${timeUntilNextLife.inHours} saat ${timeUntilNextLife.inMinutes % 60} dakika'
        : '${timeUntilNextLife.inMinutes} dakika';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                      gradient: RadialGradient(
                        colors: [Colors.red.shade100, Colors.red.shade50],
                        radius: 0.8,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade100.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.favorite,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Can Hakkınız Bitti',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Şu anda yeterli can hakkınız bulunmuyor. Her ${QuizProvider.liveRefreshHours} saatte ${QuizProvider.maxLives} can hakkı yenilenir.',
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
                        color: Colors.deepPurple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sonraki Can',
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
                              color: Colors.deepPurple,
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
                  Navigator.of(context).pop();
                  _showWatchAdDialog();
                },
                icon: const Icon(Icons.play_circle_filled, size: 20),
                label: const Text('Video İzle (+3 Can)'),
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
                      builder: (context) => const LevelSelectionPage(category: 'practice'),
                    ),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: Text(
                  'Geri Dön',
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

  void _showWatchAdDialog() {
    final QuizProvider quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.indigo.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red.shade400,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3 Can Kazan',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Kısa bir video izleyerek can kazanın',
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
                      onPressed: () => Navigator.of(context).pop(),
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
                        Navigator.of(context).pop();
                        
                        // İlk önce ödül reklamını yükle ve göster
                        final bool adShown = await AdService.showRewardedAd(
                          onRewarded: () {
                            // Ödülü sadece reklam tamamlandığında ver
                            quizProvider.addLives(3); // 3 can ekle
                            // Dialog'u göster
                            if (mounted) {
                              _showLivesEarnedDialog();
                              
                              // Can eklendikten sonra sınava devam et
                              setState(() {
                                _isQuizStarted = true;
                              });
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

  void _showLivesEarnedDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animasyonlu ikon
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
                            Colors.pink.shade300,
                            Colors.pink.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.shade200.withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
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
                '3 Can Kazandınız!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Açıklama
              Text(
                'Tebrikler! 3 yeni can hakkına sahip oldunuz. Öğrenmeye devam edebilirsiniz.',
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
                  backgroundColor: Colors.pink.shade500,
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

  Widget _buildCompletionScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF673AB7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
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
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tüm Soruları Tamamladınız',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tebrikler! Harika bir iş çıkardınız',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Geri Dön',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
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
}

class WordCardDialog extends StatefulWidget {
  final QuestionModel question;

  const WordCardDialog({
    Key? key,
    required this.question,
  }) : super(key: key);

  @override
  State<WordCardDialog> createState() => _WordCardDialogState();
}

class _WordCardDialogState extends State<WordCardDialog> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool isFlipped = false;
  final SoundService _soundService = SoundService();

  @override
  void initState() {
    super.initState();
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
      _soundService.playFlipSound();
    } else {
      _flipController.reverse();
      _soundService.playFlipSound();
    }
    
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: _flipCard,
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
            child: _flipAnimation.value < 0.5
                ? _buildFrontCard()
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackCard(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
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
                      Colors.blue.shade100,
                      Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.question.partOfSpeech,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Spacer(),
          Text(
            widget.question.word,
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
            widget.question.pronunciation,
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

  Widget _buildBackCard() {
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
              widget.question.englishMeaning,
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: primaryBlue,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.question.turkishMeaning,
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
              'EXAMPLES',
              style: GoogleFonts.poppins(
                color: subtleText,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            ...widget.question.examples.map((example) => Padding(
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
} 