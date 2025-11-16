import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../exam/exam_selection_page.dart';
import '../quiz/quiz_provider.dart';
import 'package:provider/provider.dart';
import '../learn/word_bank/word_bank_page.dart';
import '../practice/mistakes_page.dart';
import 'dart:convert';
import '../../widgets/hearts_indicator.dart';
import '../../widgets/cards_indicator.dart';
import '../../core/widgets/native_ad_widget.dart';
import '../../services/ad_service.dart';
import '../../services/premium_service.dart';
import '../home/home_page.dart';

class LevelSelectionPage extends StatefulWidget {
  final String category;
  
  const LevelSelectionPage({
    super.key,
    required this.category,
  });
  
  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  int _totalMistakeCount = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (widget.category == 'practice') {
      _loadMistakeCount();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMistakeCount() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    try {
      final prefs = await quizProvider.getPrefs();
      final countsJson = prefs?.getString('mistake_counts_by_level') ?? '{}';
      print('Level Selection - Hata sayıları JSON: $countsJson');
      
      if (countsJson != '{}') {
        final Map<String, dynamic> countsMap = jsonDecode(countsJson);
        int total = 0;
        
        countsMap.forEach((key, value) {
          if (value is int) {
            total += value;
            print('Level Selection - Seviye $key: $value hata');
          }
        });
        
        print('Level Selection - Toplam hata sayısı: $total');
        
        setState(() {
          _totalMistakeCount = total;
          _isLoading = false;
        });
      } else {
        print('Level Selection - Hata sayıları bulunamadı, getMistakes çağrılıyor');
        // Eğer kayıtlı hata sayısı yoksa, getMistakes çağırarak hesapla
        await quizProvider.getMistakes(level: 'MIX');
        
        // Tekrar kontrol et
        final updatedCountsJson = prefs?.getString('mistake_counts_by_level') ?? '{}';
        print('Level Selection - Güncellenen hata sayıları: $updatedCountsJson');
        
        if (updatedCountsJson != '{}') {
          final Map<String, dynamic> countsMap = jsonDecode(updatedCountsJson);
          int total = 0;
          
          countsMap.forEach((key, value) {
            if (value is int) {
              total += value;
              print('Level Selection - Güncellenen seviye $key: $value hata');
            }
          });
          
          print('Level Selection - Güncellenen toplam hata: $total');
          
          setState(() {
            _totalMistakeCount = total;
            _isLoading = false;
          });
        } else {
          print('Level Selection - Hala hata sayıları bulunamadı');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading mistake count: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getPageTitle() {
    if (widget.category == 'learn') {
      return 'Word Lists';
    } else {
      return 'Practice Lists';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          onPressed: () {
            // Geri tuşuna basıldığında ana sayfaya dön
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Doğrudan ana sayfaya yönlendir, onboarding kontrolünü atla
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          },
        ),
        title: Text(
          getPageTitle(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50).withOpacity(0.8),
              Color(0xFF34495E).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Practice kategorisi için can göstergesini ekle
              if (widget.category == 'practice')
                _buildLivesSection(context),
              // Learn kategorisi için kart göstergesini ekle
              if (widget.category == 'learn')
                _buildCardsSection(context),
              const SizedBox(height: 32),
              _buildWordListCard(
                context: context,
                title: 'The Oxford 3000',
                subtitle: 'Essential words for learning English',
                icon: Icons.auto_stories,
                color: Colors.blue,
                type: 'oxford_3000',
              ),
              const SizedBox(height: 16),
              _buildWordListCard(
                context: context,
                title: 'The Oxford 5000',
                subtitle: 'Advanced vocabulary for higher-level learners',
                icon: Icons.school,
                color: Colors.purple,
                type: 'oxford_5000',
              ),
              const SizedBox(height: 16),
              _buildWordListCard(
                context: context,
                title: 'American Oxford 3000',
                subtitle: 'Essential American English vocabulary',
                icon: Icons.language,
                color: Colors.red,
                type: 'american_3000',
              ),
              const SizedBox(height: 16),
              _buildWordListCard(
                context: context,
                title: 'American Oxford 5000',
                subtitle: 'Advanced American English vocabulary',
                icon: Icons.psychology,
                color: Colors.green,
                type: 'american_5000',
              ),
              const SizedBox(height: 16),
              _buildWordListCard(
                context: context,
                title: widget.category == 'learn' ? 'Word Bank' : 'Mistakes',
                subtitle: widget.category == 'learn' 
                  ? 'Comprehensive collection of English words'
                  : 'Practice words you had difficulty with',
                icon: widget.category == 'learn' ? Icons.account_balance : Icons.error_outline,
                color: Colors.orange,
                type: 'word_bank',
              ),
              const SizedBox(height: 20),
              // Sponsorlu reklam kartı - YENİ TASARIM
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sponsorlu yazısı artık beyaz kutu dışında - Premium kullanıcılara gösterilmez
                    Consumer<PremiumService>(
                      builder: (context, premiumService, _) {
                        if (premiumService.isPremium) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 6),
                          child: Text(
                            'Sponsorlu',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Theme(
                          // Install butonunun görünümünü iyileştirmek için tema veriyoruz
                          data: ThemeData(
                            // Radikal değişiklikler - AdMob'un iç mekanizmasını etkilemek için
                            // Temel renk şeması - tüm temayı etkileyecek
                            primaryColor: Colors.lightBlue,
                            primaryColorDark: Colors.lightBlue.shade700,
                            primaryColorLight: Colors.lightBlue.shade300,
                            scaffoldBackgroundColor: Colors.white,
                            dialogBackgroundColor: Colors.white,
                            cardColor: Colors.white,
                            colorScheme: ColorScheme.light(
                              primary: Colors.lightBlue,
                              secondary: Colors.lightBlue,
                              onPrimary: Colors.white,
                              onSecondary: Colors.white,
                              onBackground: Colors.black87,
                              onSurface: Colors.black87,
                              background: Colors.white,
                              surface: Colors.white,
                              brightness: Brightness.light,
                            ),
                            // Butonlar için her türlü tema ayarı
                            elevatedButtonTheme: ElevatedButtonThemeData(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue, 
                                foregroundColor: Colors.white, 
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 8
                                ),
                              ),
                            ),
                            // Eski ButtonTheme de ekleyelim (bazı AdMob sürümleri için)
                            buttonTheme: ButtonThemeData(
                              buttonColor: Colors.lightBlue,
                              textTheme: ButtonTextTheme.primary,
                              colorScheme: ColorScheme.light(
                                primary: Colors.lightBlue,
                                onPrimary: Colors.white,
                              ),
                            ),
                            // Material 3 için Text buton tema ayarları
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.lightBlue,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Eski material için buton ve text ayarları
                            primaryTextTheme: TextTheme(
                              bodyLarge: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              bodyMedium: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              labelLarge: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              titleMedium: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // Global text tema ayarları
                            textTheme: const TextTheme(
                              bodyLarge: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              bodyMedium: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              labelLarge: TextStyle(
                                color: Colors.white,  // Buton metni için
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              titleMedium: TextStyle(
                                color: Colors.white,  // Buton metni için alternatif
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              titleLarge: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              bodySmall: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            // AppBarTheme (AdMob bazen app bar stillerini kullanabilir)
                            appBarTheme: const AppBarTheme(
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                              titleTextStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          child: const NativeAdWidget(
                            height: 150,
                            margin: 0,
                            factoryId: 'levelPageNativeAd',
                          ),
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

  // Can göstergesi ve video izleme butonu ekleyen yeni metot
  Widget _buildLivesSection(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final remainingHearts = quizProvider.remainingLives;
    final maxHearts = QuizProvider.maxLives;
    
    final timeUntilNextLife = quizProvider.timeUntilNextLife;
    final minutesUntil = timeUntilNextLife.inMinutes;
    final hoursUntil = timeUntilNextLife.inHours;
    
    final timeText = hoursUntil > 0
        ? '${hoursUntil}s ${minutesUntil % 60}d'
        : '${minutesUntil}d';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2C3E50).withOpacity(0.8),
            Color(0xFF34495E).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Consumer<PremiumService>(
                builder: (context, premiumService, _) {
                  return HeartsIndicator(
                    totalHearts: maxHearts,
                    remainingHearts: remainingHearts,
                    size: 26,
                    onTap: () => !premiumService.isPremium && remainingHearts < maxHearts 
                        ? _showAddLivesDialog(context) 
                        : null,
                    showAddButton: !premiumService.isPremium && remainingHearts < maxHearts,
                  );
                },
              ),
              Consumer<PremiumService>(
                builder: (context, premiumService, _) {
                  // Premium kullanıcılar için video izleme butonunu gizle
                  if (premiumService.isPremium) return SizedBox();
                  
                  if (remainingHearts < maxHearts)
                    return ElevatedButton.icon(
                      onPressed: () => _showWatchAdDialog(context),
                      icon: Icon(Icons.play_circle_fill, color: Colors.blue.shade600, size: 18),
                      label: Text('Video İzle +3', 
                        style: GoogleFonts.poppins(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200, width: 1),
                        ),
                        elevation: 2,
                        shadowColor: Colors.blue.shade100.withOpacity(0.5),
                      ),
                    );
                  return SizedBox();
                },
              ),
            ],
          ),
          if (remainingHearts < maxHearts)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Sonraki can: $timeText',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Video reklamı izleme diyaloğu - daha güzel bir tasarım
  void _showWatchAdDialog(BuildContext context) {
    // QuizProvider'ı diyaloğa girmeden önce al
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100.withOpacity(0.5),
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        backgroundColor: Colors.white,
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
                            quizProvider.addLives(3); // 3 can ekle
                            // Dialog'u göster
                            if (mounted) {
                              _showLivesEarnedDialog(context);
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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
  
  // Can ekleme diyaloğu
  void _showAddLivesDialog(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final timeUntilNextLife = quizProvider.timeUntilNextLife;
    
    final String timeText = timeUntilNextLife.inHours > 0
        ? '${timeUntilNextLife.inHours} saat ${timeUntilNextLife.inMinutes % 60} dakika'
        : '${timeUntilNextLife.inMinutes} dakika';
    
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
                        colors: [
                          Color(0xFF2C3E50).withOpacity(0.8),
                          Color(0xFF34495E).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                  Navigator.of(dialogContext).pop();
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

  // Kart hakları için bir bölüm ekleyen metot
  Widget _buildCardsSection(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final remainingCards = quizProvider.remainingCards;
    final maxCards = QuizProvider.maxCards;
    
    final timeUntilNextCard = quizProvider.timeUntilNextCard;
    final minutesUntil = timeUntilNextCard.inMinutes;
    final hoursUntil = timeUntilNextCard.inHours;
    
    final timeText = hoursUntil > 0
        ? '${hoursUntil}s ${minutesUntil % 60}d'
        : '${minutesUntil}d';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2C3E50).withOpacity(0.8),
            Color(0xFF34495E).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CardsIndicator(
                totalCards: maxCards,
                remainingCards: remainingCards,
                size: 26,
                onTap: () => remainingCards < maxCards 
                    ? _showAddCardsDialog(context) 
                    : null,
                showAddButton: remainingCards < maxCards,
              ),
              if (remainingCards < maxCards)
                ElevatedButton.icon(
                  onPressed: () => _showWatchCardAdDialog(context),
                  icon: Icon(Icons.play_circle_fill, color: Colors.green.shade600, size: 18),
                  label: Text('Video İzle +25', 
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.green.shade200, width: 1),
                    ),
                    elevation: 2,
                    shadowColor: Colors.green.shade100.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          if (remainingCards < maxCards)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Sonraki Kart Destesine: $timeText',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWordListCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    // Eğer bu öğe Word Bank veya Mistakes ise, doğru yönlendirmeyi yap
    if (type == 'word_bank') {
      return GestureDetector(
        onTap: () {
          if (widget.category == 'learn') {
            // Learn kategorisinde kart hakkı kontrolü
            final remainingCards = quizProvider.remainingCards;
            if (remainingCards <= 0) {
              _showNoCardsDialog(context);
              return;
            }
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WordBankPage(),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
                _loadMistakeCount();
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MistakesPage(),
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
                _loadMistakeCount();
              }
            });
          }
        },
        child: _buildCard(title, subtitle, icon, color),
      );
    }

    return GestureDetector(
      onTap: () {
        if (widget.category == 'practice') {
          // Can sistemi kontrolü
          final remainingLives = quizProvider.remainingLives;
          if (remainingLives <= 0) {
            _showNoLivesDialog(context);
            return;
          }
        } else if (widget.category == 'learn') {
          // Kart hakkı kontrolü
          final remainingCards = quizProvider.remainingCards;
          if (remainingCards <= 0) {
            _showNoCardsDialog(context);
            return;
          }
        }
        
        // Sınav seçim sayfasına geç
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamSelectionPage(
              category: widget.category,
              wordListType: type,
            ),
          ),
        );
      },
      child: _buildCard(title, subtitle, icon, color),
    );
  }

  // Can bittiğinde gösterilecek dialog
  void _showNoLivesDialog(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final timeUntilNextLife = quizProvider.timeUntilNextLife;
    
    final String timeText = timeUntilNextLife.inHours > 0
        ? '${timeUntilNextLife.inHours} saat ${timeUntilNextLife.inMinutes % 60} dakika'
        : '${timeUntilNextLife.inMinutes} dakika';
    
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
                        colors: [
                          Color(0xFF2C3E50).withOpacity(0.8),
                          Color(0xFF34495E).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                  // Navigasyon yığınını temizleyerek ana sayfaya dönüş yapılmasını sağla
                  
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

  Widget _buildCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9E9E9E),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Video reklamı izleyerek kart kazanma diyaloğu
  void _showWatchCardAdDialog(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade200.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade100.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_fill,
                    size: 48,
                    color: Colors.green.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Video İzle',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade100.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        backgroundColor: Colors.white,
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
                            quizProvider.addCards(25); // 10 kart yerine 25 kart ekle
                            // Dialog'u göster
                            if (mounted) {
                              _showCardEarnedDialog(context);
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
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
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
  
  // Kart hakkı ekleme diyaloğu
  void _showAddCardsDialog(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final timeUntilNextCard = quizProvider.timeUntilNextCard;
    
    final String timeText = timeUntilNextCard.inHours > 0
        ? '${timeUntilNextCard.inHours} saat ${timeUntilNextCard.inMinutes % 60} dakika'
        : '${timeUntilNextCard.inMinutes} dakika';
    
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
                        colors: [
                          Color(0xFF2C3E50).withOpacity(0.8),
                          Color(0xFF34495E).withOpacity(0.8),
                        ],
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
  
  void _showCardEarnedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
        );
      },
    );
  }

  void _showLivesEarnedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
        );
      },
    );
  }

  // Kart hakları bittiğinde gösterilecek dialog
  void _showNoCardsDialog(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final timeUntilNextCard = quizProvider.timeUntilNextCard;
    
    final String timeText = timeUntilNextCard.inHours > 0
        ? '${timeUntilNextCard.inHours} saat ${timeUntilNextCard.inMinutes % 60} dakika'
        : '${timeUntilNextCard.inMinutes} dakika';
    
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
                        colors: [
                          Color(0xFF2C3E50).withOpacity(0.8),
                          Color(0xFF34495E).withOpacity(0.8),
                        ],
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
                  Navigator.of(context).pop();
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
} 