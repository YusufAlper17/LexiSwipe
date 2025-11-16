import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../modules/home/home_page.dart';
import '../../../widgets/hearts_indicator.dart';
import '../../../widgets/cards_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/onboarding_widget_previews.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;
  bool _isCardFlipped = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade500,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // İlerleme göstergesi
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Row(
                  children: [
                    for (int i = 0; i < _totalPages; i++)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _currentPage
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Atlama butonu
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Atla',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Ana içerik
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildLearnPracticePage(),
                    _buildLivesPage(),
                    _buildCardsPage(),
                    _buildSwipingPage(),
                    _buildWordBankMistakesPage(),
                  ],
                ),
              ),
              
              // Navigasyon butonları
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Geri butonu
                    _currentPage > 0
                        ? TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Geri',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    
                    // İleri/Başla butonu
                    ElevatedButton(
                      onPressed: _currentPage < _totalPages - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < _totalPages - 1 ? 'İleri' : 'Başla',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
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

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          
          // Başlık
          Text(
            'LexiSwipe\'a Hoş Geldiniz!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Açıklama
          Text(
            'Bu rehber size uygulamayı nasıl kullanabileceğinizi adım adım gösterecek.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnPracticePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'İki Ana Bölüm',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Learn Kartı
            _buildFeatureCard(
              title: 'Learn',
              icon: Icons.school,
              color: Colors.orange,
              description: 'Yeni kelimeler öğrenmek için kullanılır. Kelimeleri sağa veya sola kaydırarak ilerlersiniz.',
            ),
            const SizedBox(height: 24),
            
            // Practice Kartı
            _buildFeatureCard(
              title: 'Practice',
              icon: Icons.psychology,
              color: Colors.green,
              description: 'Öğrendiğiniz kelimeleri test etmek için quiz formatında sorular çözersiniz.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivesPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Can Sistemi',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Can göstergesi örneği
            const HeartsIndicator(
              totalHearts: 5,
              remainingHearts: 3,
              size: 32,
            ),
            const SizedBox(height: 24),
            
            _buildInfoCard(
              title: 'Can Nasıl Çalışır?',
              points: [
                'Quiz çözerken her yanlış cevap için 1 can kaybedersiniz.',
                'Toplam 5 can hakkınız bulunur.',
                'Her 4 saatte bir canlarınız yenilenir.',
                'Can hakkınız bittiğinde reklam izleyerek can kazanabilirsiniz.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kart Sistemi',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Kart göstergesi örneği
            const CardsIndicator(
              totalCards: 30,
              remainingCards: 20,
              size: 32,
            ),
            const SizedBox(height: 24),
            
            _buildInfoCard(
              title: 'Kartlar Nasıl Çalışır?',
              points: [
                'Learn bölümünde her kelime kartı için 1 kart hakkı harcanır.',
                'Toplam 50 kart hakkınız bulunur.',
                'Her 4 saatte bir kart haklarınız yenilenir.',
                'Kart hakkınız bittiğinde reklam izleyerek ek kartlar kazanabilirsiniz.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipingPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kart Kaydırma',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Kelime kartı önizlemesi
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCardFlipped = !_isCardFlipped;
                });
              },
              child: Center(
                child: WordCardPreview(isFlipped: _isCardFlipped),
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Kartlara dokunarak ön yüz (kelime) ve\narka yüz (anlam) arasında geçiş yapabilirsiniz',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 24),
            
            // Kaydırma illüstrasyonu
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSwipeCard(
                  'Sola Kaydır',
                  Icons.swipe_left,
                  'Kelimeyi bilmiyorum',
                  Colors.red.shade400,
                ),
                const SizedBox(width: 20),
                _buildSwipeCard(
                  'Sağa Kaydır',
                  Icons.swipe_right,
                  'Kelimeyi öğrendim',
                  Colors.green.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordBankMistakesPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Özel Bölümler',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Word Bank Kartı
            _buildFeatureCard(
              title: 'Word Bank',
              icon: Icons.menu_book,
              color: Colors.purple,
              description: 'Sola kaydırdığınız kelimeler burada saklanır. İstediğiniz zaman tekrar gözden geçirebilirsiniz.',
              preview: const SizedBox(
                height: 160,
                child: WordBankPreview(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Mistakes Kartı
            _buildFeatureCard(
              title: 'Mistakes',
              icon: Icons.error_outline,
              color: Colors.red,
              description: 'Practice bölümünde yaptığınız hatalar burada listelenir. Tekrar çalışarak hatalarınızı düzeltebilirsiniz.',
              preview: const SizedBox(
                height: 160,
                child: MistakesPreview(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    Widget? preview,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 16),
            preview,
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...points.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSwipeCard(
    String title,
    IconData icon,
    String description,
    Color color,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.7),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
} 