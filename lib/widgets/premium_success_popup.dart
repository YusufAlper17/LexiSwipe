import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class PremiumSuccessPopup extends StatefulWidget {
  final VoidCallback onClose;

  const PremiumSuccessPopup({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<PremiumSuccessPopup> createState() => _PremiumSuccessPopupState();
}

class _PremiumSuccessPopupState extends State<PremiumSuccessPopup> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeInAnimation;
  
  // Özellikler için animasyon değişkenleri
  late List<AnimationController> _featureAnimationControllers;
  late List<Animation<Offset>> _featureAnimations;
  
  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();
    
    // Ana popup animasyonu
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      )
    );
    
    // Konfeti animasyonu
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Özellikler için animasyon kontrolcüleri
    _featureAnimationControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 100)),
      );
    });
    
    // Özellikler için animasyonlar
    _featureAnimations = List.generate(3, (index) {
      return Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _featureAnimationControllers[index],
          curve: Curves.easeOutCubic,
        ),
      );
    });
    
    _animationController.forward();
    
    // Sırayla özellikleri göster
    Future.delayed(const Duration(milliseconds: 300), () {
      _featureAnimationControllers[0].forward();
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      _featureAnimationControllers[1].forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _featureAnimationControllers[2].forward();
    });
    
    // Konfeti animasyonunu başlat
    Future.delayed(const Duration(milliseconds: 600), () {
      _confettiController.forward();
    });
    
    // 5 saniye sonra konfetiyi gizle
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    for (var controller in _featureAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Geri tuşuyla çıkılamaz
        return false;
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arka plan karartma ve parıltı efekti
          AnimatedBuilder(
            animation: _fadeInAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeInAnimation.value * 0.8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),
              );
            }
          ),
          
          // Konfeti animasyonu (üst kısımda)
          if (_showConfetti)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 200,
                child: Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_ncpnijkz.json', // Konfeti animasyonu
                  controller: _confettiController,
                  repeat: true,
                ),
              ),
            ),
            
          // Ana popup içeriği
          ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.amber.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animasyon
                    SizedBox(
                      height: 150,
                      child: Lottie.network(
                        'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', // Premium/VIP animasyonu
                        repeat: true,
                        animate: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Başlık - Fade-in animasyonu ile
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Text(
                        'Premium Paket Aktif!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Açıklama - Fade-in animasyonu ile
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: Text(
                        'Tebrikler! Artık premium üyesiniz. Tüm premium özelliklere erişim sağladınız ve reklamlardan kurtuldunuz.',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Premium özellikleri - Slayt animasyonu ile
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SlideTransition(
                            position: _featureAnimations[0],
                            child: _buildFeatureItem(Icons.block, 'Reklamlar Kaldırıldı'),
                          ),
                          const SizedBox(height: 12),
                          SlideTransition(
                            position: _featureAnimations[1],
                            child: _buildFeatureItem(Icons.all_inclusive, 'Sınırsız Kullanım'),
                          ),
                          const SizedBox(height: 12),
                          SlideTransition(
                            position: _featureAnimations[2],
                            child: _buildFeatureItem(Icons.star, 'Özel İçerikler'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Kapat butonu - Pulse animasyonu ile
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: ElevatedButton(
                            onPressed: widget.onClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.celebration, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Harika!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.amber.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.amber.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 