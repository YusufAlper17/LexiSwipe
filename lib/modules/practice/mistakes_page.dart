import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import '../quiz/quiz_provider.dart';
import '../quiz/models/question_model.dart';
import '../quiz/quiz_page.dart';
import '../../utils/color_palette.dart';
import '../../widgets/score_indicator.dart';
import 'dart:math' as math;
import '../../core/widgets/native_ad_widget.dart';
import '../../services/ad_service.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../services/premium_service.dart';

class MistakesPage extends StatefulWidget {
  const MistakesPage({Key? key}) : super(key: key);

  @override
  State<MistakesPage> createState() => _MistakesPageState();
}

class _MistakesPageState extends State<MistakesPage> {
  String _selectedLevel = 'MIX';
  String _selectedCategory = 'all';
  bool _isLoading = false;
  List<QuestionModel> _questions = [];
  
  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }
  
  Future<void> _loadMistakes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Doğrudan kaydedilen hataları yükle
      final questions = await Provider.of<QuizProvider>(context, listen: false)
          .getDirectMistakes();
      
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      
      print('Doğrudan hatalar yüklendi. Toplam: ${_questions.length}');
      
      // Seviye bazında hata sayılarını logla
      Map<String, int> levelCounts = {};
      for (var q in _questions) {
        levelCounts[q.level] = (levelCounts[q.level] ?? 0) + 1;
      }
      
      levelCounts.forEach((level, count) {
        print('$level seviyesinde $count hata var');
      });
      
    } catch (e) {
      print('Hatalar yüklenirken hata oluştu: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFFFFFFFF),
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFFFFFF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mistakes',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_sweep,
                          color: Color(0xFFFFFFFF),
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFFF5F5F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text('Tüm Hataları Temizle', 
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF000000),
                              )),
                            content: Text(
                              'Tüm hataları temizlemek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF616161),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF616161),
                                ),
                                child: Text('İptal', style: GoogleFonts.poppins()),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                                  
                                  print('Tüm hatalar temizleniyor...');
                                  // Eski ve yeni hata sistemlerini temizle
                                  await quizProvider.clearAllMistakes();
                                  await quizProvider.clearAllDirectMistakes();
                                  print('Tüm hatalar temizlendi!');
                                  
                                  // Sayfa verilerini yenile
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  await _loadMistakes();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFE53935),
                                ),
                                child: Text('Temizle', style: GoogleFonts.poppins()),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select Level',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFFFFF)))
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLevelCard(
                            context: context,
                            title: 'Mix',
                            subtitle: 'Mixed Level Practice',
                            icon: Icons.shuffle,
                            color: Colors.amber,
                            count: _questions.length,
                          ),
                          const SizedBox(height: 16),
                          _buildLevelCard(
                            context: context,
                            title: 'A1 Level',
                            subtitle: 'Beginner',
                            icon: Icons.star_border,
                            color: Colors.green,
                            count: _questions.where((q) => q.level == 'A1').length,
                          ),
                          const SizedBox(height: 16),
                          _buildLevelCard(
                            context: context,
                            title: 'A2 Level',
                            subtitle: 'Elementary',
                            icon: Icons.star_half,
                            color: Colors.lightBlue,
                            count: _questions.where((q) => q.level == 'A2').length,
                          ),
                          const SizedBox(height: 16),
                          _buildLevelCard(
                            context: context,
                            title: 'B1 Level',
                            subtitle: 'Intermediate',
                            icon: Icons.star,
                            color: Colors.orange,
                            count: _questions.where((q) => q.level == 'B1').length,
                          ),
                          const SizedBox(height: 16),
                          _buildLevelCard(
                            context: context,
                            title: 'B2 Level',
                            subtitle: 'Upper Intermediate',
                            icon: Icons.stars,
                            color: Colors.redAccent,
                            count: _questions.where((q) => q.level == 'B2').length,
                          ),
                          const SizedBox(height: 16),
                          _buildLevelCard(
                            context: context,
                            title: 'C1 Level',
                            subtitle: 'Advanced',
                            icon: Icons.workspace_premium,
                            color: Colors.purple,
                            count: _questions.where((q) => q.level == 'C1').length,
                          ),
                          const SizedBox(height: 16),
                          // Native reklam widget'ı içerik kartı olarak ekle
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 180,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              child: NativeAdWidget(
                                height: 180,
                                margin: 0,
                                factoryId: _selectedCategory == 'oxford_3000' 
                                    ? 'practiceOxford3000NativeAd'
                                    : _selectedCategory == 'oxford_5000'
                                        ? 'practiceOxford5000NativeAd'
                                        : _selectedCategory == 'american_3000'
                                            ? 'practiceAmericanOxford3000NativeAd'
                                            : _selectedCategory == 'american_5000'
                                                ? 'practiceAmericanOxford5000NativeAd'
                                                : 'mistakesPageNativeAd',
                              ),
                            ),
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

  void _onLevelSelected(String level) {
    setState(() {
      _selectedLevel = level;
      _isLoading = true;
    });
    
    print('Seviye seçildi: $level');
    
    // Doğrudan kaydedilen hatalar seviye filtrelemesi desteklemiyor
    // Bu nedenle tüm hataları yükleyip filtreleme işlemini burada yapıyoruz
    Provider.of<QuizProvider>(context, listen: false)
        .getDirectMistakes()
        .then((allQuestions) {
          setState(() {
            if (level == 'MIX') {
              _questions = allQuestions;
              print('MIX seviyesi seçildi, tüm hatalar gösteriliyor. Toplam: ${_questions.length}');
            } else {
              _questions = allQuestions
                  .where((q) => q.level.toUpperCase() == level)
                  .toList();
              print('$level seviyesi seçildi, filtrelenmiş hatalar gösteriliyor. Toplam: ${_questions.length}');
            }
            _isLoading = false;
          });
        });
  }
  
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    
    // Doğrudan kaydedilen hatalar kategori filtrelemesi desteklemiyor
    // Bu nedenle şimdilik bu özelliği devre dışı bırakıyoruz
    _loadMistakes();
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int count,
  }) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final premiumService = Provider.of<PremiumService>(context);
    bool hasLives = premiumService.isPremium || quizProvider.hasEnoughLives();
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () async {
          if (!hasLives && !premiumService.isPremium) {
            _showNoLivesDialog(context);
            return;
          }
          
          if (count <= 0) {
            // Eğer bu seviyede kelime yoksa, bir şey yapma
            CustomSnackbar.showWarning(
              context,
              'Kelime bulunamadı.'
            );
            return;
          }
          
          try {
            setState(() {
              _isLoading = true;
            });
            
            final mistakesLevel = title == 'Mix' ? 'MIX' : title.split(' ')[0];
            print('Level kartına tıklandı: $mistakesLevel');
            
            // Doğrudan hataları getir
            final filteredMistakes = await quizProvider.getDirectMistakes();
            
            // Seviyeye göre filtrele (MIX dışında)
            List<QuestionModel> quizQuestions;
            if (mistakesLevel != 'MIX') {
              print('$mistakesLevel seviyesi için hatalar filtreleniyor...');
              quizQuestions = filteredMistakes
                  .where((q) => q.level.toUpperCase() == mistakesLevel)
                  .toList();
            } else {
              quizQuestions = filteredMistakes;
            }
            
            print('Quiz başlatılıyor. Soru sayısı: ${quizQuestions.length}');
            
            // Eğer hala mounted isek
            if (mounted) {
              // Yeterli soru varsa Quiz sayfasına git
              if (quizQuestions.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuizPage(
                      questions: quizQuestions,
                      category: 'mistakes',
                      level: mistakesLevel,
                      examNumber: 0,
                      isCustomQuiz: true, // Özel quiz kullanılacak
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    // Geri döndüğünde hataları yeniden yükle
                    setState(() {
                      _isLoading = true;
                    });
                    _loadMistakes();
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Bu seviyede hiç hata bulunamadı.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {
                  _isLoading = false;
                });
              }
            }
          } catch (e) {
            print('Hatalar yüklenirken hata oluştu: $e');
            
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              CustomSnackbar.showError(
                context,
                'Sorular yüklenirken hata oluştu: ${e.toString()}'
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: count > 0 ? const Color(0xFFE3F2FD) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  count > 0 ? '$count kelime' : 'Boş',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: count > 0 ? const Color(0xFF1976D2) : const Color(0xFF757575),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              !hasLives
                ? Icon(Icons.lock, color: const Color(0xFFEF5350), size: 22)
                : count > 0
                  ? const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E), size: 22)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  // Can hakkı bittiğinde gösterilecek dialog
  void _showNoLivesDialog(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final premiumService = Provider.of<PremiumService>(context, listen: false);
    
    // Premium kullanıcılar için dialog gösterme - güvenlik kontrolü
    if (premiumService.isPremium) return;
    
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
        backgroundColor: Colors.white,
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
                  _showWatchAdDialog(context);
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
                  Navigator.of(context).pushNamedAndRemoveUntil('/level_selection', (route) => false);
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

  void _showWatchAdDialog(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Video İzle',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reklam izleyerek 3 can hakkı kazanabilirsiniz.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'İptal',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        
                        // İlk önce ödül reklamını yükle ve göster
                        final bool adShown = await AdService.showRewardedAd(
                          onRewarded: () {
                            // Ödülü sadece reklam tamamlandığında ver
                            quizProvider.addLives(3); // 3 can ekle
                            // Dialog'u göster
                            if (mounted) {
                              _showLivesEarnedDialog(context);
                            }
                          }
                        );
                        
                        // Reklam gösterilemezse kullanıcıya bildir
                        if (!adShown && mounted) {
                          CustomSnackbar.showError(
                            context,
                            'Reklam gösterilemiyor. Lütfen daha sonra tekrar deneyin.'
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

  void _showLivesEarnedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tebrikler!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tüm soruları doğru cevapladınız.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Harika!',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
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

class MistakesQuizPage extends StatefulWidget {
  final String level;
  
  const MistakesQuizPage({Key? key, required this.level}) : super(key: key);

  @override
  State<MistakesQuizPage> createState() => _MistakesQuizPageState();
}

class _MistakesQuizPageState extends State<MistakesQuizPage> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<QuestionModel> _mistakes = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _lastVisitedQuestionIndex = 0;
  int? _selectedAnswer;
  List<int?> _userAnswers = [];
  int _score = 0;
  int _remainingLives = 5;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  int _getLastVisitedQuestionIndex() {
    int lastAnsweredIndex = -1;
    for (int i = 0; i < _userAnswers.length; i++) {
      if (_userAnswers[i] != null) {
        lastAnsweredIndex = i;
      }
    }
    
    if (lastAnsweredIndex == -1 || lastAnsweredIndex >= _mistakes.length - 1) {
      return _lastVisitedQuestionIndex;
    }
    
    return lastAnsweredIndex + 1;
  }

  Future<void> _loadMistakes() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Doğrudan hataları yükle ve seviyeye göre filtrele
      List<QuestionModel> allMistakes = await quizProvider.getDirectMistakes();
      
      if (allMistakes.isEmpty) {
        print('Hiç hata bulunamadı!');
        setState(() {
          _mistakes = [];
          _userAnswers = [];
          _isLoading = false;
        });
        return;
      }
      
      // Seviyeye göre filtreleme
      List<QuestionModel> filteredMistakes;
      if (widget.level.toUpperCase() != 'MIX') {
        filteredMistakes = allMistakes
            .where((q) => q.level.toUpperCase() == widget.level.toUpperCase())
            .toList();
        print('${widget.level} seviyesi için hatalar yüklendi. Toplam: ${filteredMistakes.length}');
      } else {
        filteredMistakes = allMistakes;
        print('Tüm seviyeler (MIX) için hatalar yüklendi. Toplam: ${filteredMistakes.length}');
      }
      
      // Soruları karıştır
      filteredMistakes.shuffle();
      
      setState(() {
        _mistakes = filteredMistakes;
        // Eğer _userAnswers boşsa veya yeni liste farklı uzunluktaysa, yeni bir liste oluştur
        if (_userAnswers.isEmpty || _userAnswers.length != filteredMistakes.length) {
          _userAnswers = List.filled(filteredMistakes.length, null); // Tüm cevapları null olarak başlat
        }
        // Diğer değişkenleri sadece ilk yüklemede sıfırla
        if (_currentQuestionIndex >= filteredMistakes.length) {
          _currentQuestionIndex = 0;
        }
        if (_lastVisitedQuestionIndex >= filteredMistakes.length) {
          _lastVisitedQuestionIndex = 0;
        }
        _isLoading = false;
      });
      
      print('Hatalar yüklendi ve hazır. Toplam soru: ${_mistakes.length}');
    } catch (e) {
      print('Hatalar yüklenirken hata oluştu: $e');
      setState(() {
        _isLoading = false;
        _mistakes = [];
      });
    }
  }

  Future<void> _playSound(String soundPath) async {
    try {
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> _playWordAudio(String audioUrl) async {
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void _selectAnswer(int answerIndex) {
    // Eğer bu soru zaten cevaplanmışsa, hiçbir şey yapma
    if (_userAnswers[_currentQuestionIndex] != null) return;
    
    // Önce sadece seçimi göster, doğru/yanlış kontrolü henüz yapma
    setState(() {
      _selectedAnswer = answerIndex;
    });
    
    // Cevap doğruluğunu kontrol etmek için geciktirme
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      
      // Doğru/yanlış kontrolü
      final isCorrect = answerIndex == _mistakes[_currentQuestionIndex].correctOptionIndex;
      final currentWord = _mistakes[_currentQuestionIndex].word;
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      
      setState(() {
        // Kullanıcının cevabını kaydet
        _userAnswers[_currentQuestionIndex] = answerIndex;
        
        if (isCorrect) {
          // Doğru cevap
          _playSound('sounds/mixkit-correct-answer-tone-2870.wav');
          _score += 10;
          
          // Kelimeyi hatalar listesinden kaldır (doğru yapılan kelimeler listeden çıkarılır)
          quizProvider.removeDirectMistake(currentWord);
          print('Doğru cevap! Kelime hatalar listesinden kaldırıldı: $currentWord');
          
          // Not: Burada _mistakes listesini güncellemeye gerek yok
          // Çünkü tüm sorular tamamlandığında _reloadMistakesAndShowWrongAnswers
          // metodu ile hatalar tekrar yüklenecek
        } else {
          // Yanlış cevap
          _playSound('sounds/error-8-206492.mp3');
          _remainingLives--;
          print('Yanlış cevap! Kelime hatalar listesinde kalacak: $currentWord');
          
          // Canlar bittiğinde diyalog göster
          if (_remainingLives <= 0) {
            _showLivesEndedDialog();
            return; // Canlari bittiyse sonraki soruya geçmeyi engelle
          }
        }
      });
      
      // Sonraki soruya geçmek için geciktirme
      Duration delay = isCorrect 
          ? const Duration(milliseconds: 1500) 
          : const Duration(milliseconds: 2500);
      
      Future.delayed(delay, () {
        if (!mounted) return;
        
        setState(() {
          _nextQuestion();
        });
      });
    });
  }
  
  // Can hakkı bittiğinde gösterilecek diyalog
  void _showLivesEndedDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tebrikler!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tüm soruları doğru cevapladınız.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil("/level_selection", (route) => false);
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Harika!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextQuestion() {
    // Eğer listedeki sonraki soruya geçebiliyorsak, sadece indeksi arttır
    if (_currentQuestionIndex < _mistakes.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
        
        if (_currentQuestionIndex > _lastVisitedQuestionIndex) {
          _lastVisitedQuestionIndex = _currentQuestionIndex;
        }
      });
    } else {
      // Son soruya geldiğimizde:
      // 1. Yanlış cevaplanan veya cevaplanmamış soruları bul
      List<int> wrongOrUnansweredIndexes = [];
      
      for (int i = 0; i < _mistakes.length; i++) {
        // Eğer soru cevaplanmamışsa veya yanlış cevaplanmışsa
        if (_userAnswers[i] == null || _userAnswers[i] != _mistakes[i].correctOptionIndex) {
          wrongOrUnansweredIndexes.add(i);
        }
      }
      
      print('Yanlış veya cevaplanmamış soru sayısı: ${wrongOrUnansweredIndexes.length}');
      
      // Eğer tüm sorular doğru cevaplanmışsa
      if (wrongOrUnansweredIndexes.isEmpty) {
        print('Tüm sorular doğru cevaplandı, quiz tamamlanıyor.');
        
        // Tamamlama diyaloğunu göster
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tebrikler!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tüm soruları doğru cevapladınız.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil("/level_selection", (route) => false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Harika!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Eğer hala yanlış veya cevaplanmamış soru varsa, hataları tekrar yükle ve ilk yanlışa dön
        // Bu, doğru cevaplanan soruların listeden çıkarılması nedeniyle oluşan indeks karışıklığını önler
        _reloadMistakesAndShowWrongAnswers(wrongOrUnansweredIndexes);
      }
    }
  }

  // Hataları tekrar yükle ve yanlış cevaplanan sorulara yönlendir
  Future<void> _reloadMistakesAndShowWrongAnswers(List<int> wrongIndexes) async {
    if (wrongIndexes.isEmpty) return;
    
    // Yanlış cevaplanan kelimeleri kaydet
    List<String> wrongWords = [];
    for (int index in wrongIndexes) {
      if (index < _mistakes.length) {
        wrongWords.add(_mistakes[index].word);
      }
    }
    
    print('Yanlış cevaplanan kelimeler: $wrongWords');
    
    // Hataları tekrar yükle
    await _loadMistakes();
    
    if (_mistakes.isEmpty) {
      print('Hatalar tekrar yüklenirken liste boş geldi.');
      return;
    }
    
    // Yanlış cevaplanan ilk kelimeyi bul
    int newIndex = -1;
    for (int i = 0; i < _mistakes.length; i++) {
      if (wrongWords.contains(_mistakes[i].word)) {
        newIndex = i;
        break;
      }
    }
    
    if (newIndex == -1) {
      print('Yanlış cevaplanan kelimeler yeni listede bulunamadı.');
      newIndex = 0; // İlk sorudan başla
    }
    
    setState(() {
      _currentQuestionIndex = newIndex;
      _selectedAnswer = null; // Yeni cevap verebilmesi için seçimi temizle
      print('Yanlış cevaplanan soru tespit edildi, yeni indeks: $_currentQuestionIndex');
    });
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        // Eğer önceki soruya dönüldüğünde, bu soru daha önce cevaplanmışsa
        // cevabı göster, cevaplanmamışsa null olarak bırak
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Container(
              decoration: const BoxDecoration(
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
            )
          : _mistakes.isEmpty
              ? Container(
                  decoration: const BoxDecoration(
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
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 80,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Henüz hata yok!',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pratik bölümünde yanlış cevapladığınız kelimeler burada görünecek.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Geri Dön',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
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
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Text(
                                'Hatalar - ${widget.level}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  ScoreIndicator(
                                    score: _score,
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
                                              _mistakes[_currentQuestionIndex].partOfSpeech,
                                              style: TextStyle(
                                                color: Colors.deepPurple.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _playWordAudio(_mistakes[_currentQuestionIndex].audioUrl);
                                            },
                                            icon: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.volume_up,
                                                color: Colors.blue.shade700,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _mistakes[_currentQuestionIndex].word,
                                        style: GoogleFonts.poppins(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade900,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Doğru Türkçe anlamını seçin',
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
                                
                                ...(_mistakes[_currentQuestionIndex].options.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final option = entry.value;
                                  
                                  return _buildOptionButton(
                                    index: index, 
                                    text: option, 
                                    question: _mistakes[_currentQuestionIndex],
                                  );
                                })),
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
                                onPressed: _currentQuestionIndex > 0
                                    ? () => _previousQuestion()
                                    : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _currentQuestionIndex > 0
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios,
                                    color: _currentQuestionIndex > 0
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                              IconButton(
                                onPressed: _currentQuestionIndex < _mistakes.length - 1 &&
                                          (_userAnswers[_currentQuestionIndex] != null || 
                                           _currentQuestionIndex < _getLastVisitedQuestionIndex())
                                  ? () => _nextQuestion()
                                  : null,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _currentQuestionIndex < _mistakes.length - 1 &&
                                          (_userAnswers[_currentQuestionIndex] != null || 
                                           _currentQuestionIndex < _getLastVisitedQuestionIndex())
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    color: _currentQuestionIndex < _mistakes.length - 1 &&
                                          (_userAnswers[_currentQuestionIndex] != null || 
                                           _currentQuestionIndex < _getLastVisitedQuestionIndex())
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
    );
  }

  Widget _buildOptionButton({required int index, required String text, required QuestionModel question}) {
    final isSelected = _userAnswers[_currentQuestionIndex] == index;
    final isPreSelected = _selectedAnswer == index;
    final isCorrect = index == question.correctOptionIndex;
    final showCorrectAnswer = _userAnswers[_currentQuestionIndex] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showCorrectAnswer ? null : () => _selectAnswer(index),
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
} 