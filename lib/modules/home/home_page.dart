import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../level/level_selection_page.dart';
import '../../modules/quiz/quiz_provider.dart';
import '../../core/widgets/custom_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // TimeoutException için import
import '../../services/sound_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/widgets/native_ad_widget.dart';
import '../../services/premium_service.dart'; // Premium servisi ekledik
import 'package:flutter/foundation.dart'; // kDebugMode için import
import '../../widgets/premium_success_popup.dart';
import '../../core/widgets/custom_snackbar.dart';

// Triangle clipper sınıfları
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class RightTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool isSoundEnabled = true;
  final SoundService _soundService = SoundService();
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // QuizProvider'ı başlat ve ilerlemeyi yükle
      await context.read<QuizProvider>().init();
      
      // Ses ayarlarını yükle
      await _loadSoundState();
      
    } catch (e) {
      print('Uygulama başlatılırken hata: $e');
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Uygulama başlatılırken bir hata oluştu. Lütfen daha sonra tekrar deneyin.'
        );
      }
    }
  }

  Future<void> _loadSoundState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
      _soundService.setSoundEnabled(isSoundEnabled);
    });
  }

  Future<void> _saveSoundState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundEnabled', isSoundEnabled);
    _soundService.setSoundEnabled(isSoundEnabled);
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
              const SizedBox(width: 10),
              Text(
                'İlerlemeyi Sıfırla',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tüm ilerlemenizi sıfırlamak üzeresiniz. Bu işlem geri alınamaz!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Silinecek veriler:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildDataItem(Icons.quiz_outlined, 'Quiz Sonuçları ve İlerlemeler'),
              _buildDataItem(Icons.menu_book_outlined, 'Kelime Bankası'),
              _buildDataItem(Icons.error_outline, 'Hatalar ve Notlar'),
              _buildDataItem(Icons.bar_chart, 'İstatistikler'),
              _buildDataItem(Icons.lock_open, 'Seviye Kilitleri'),
              _buildDataItem(Icons.settings, 'Uygulama Ayarları'),
              const SizedBox(height: 16),
              Text(
                'Uyarı: Bu işlem uygulamayı yeni kurulmuş haline getirecektir ve geri alınamaz.',
                style: GoogleFonts.poppins(
                  fontStyle: FontStyle.italic,
                  color: Colors.red[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
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
                // Dialog'u kapat
                Navigator.of(dialogContext).pop();
                
                // Ana context'ten QuizProvider'a erişelim
                final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                
                // Yükleniyor göstergesi
                if (!context.mounted) return;
                
                // Yükleniyor dialog'unu göster
                late BuildContext loadingDialogContext;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext ctx) {
                    loadingDialogContext = ctx;
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(
                              'Tüm veriler sıfırlanıyor...',
                              style: GoogleFonts.poppins(),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Lütfen bekleyin, bu işlem biraz zaman alabilir.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
                
                try {
                  // Reset işlemini yap - 30 saniye timeout ile
                  bool isCompleted = false;
                  
                  // İşlemi ana bağlama göre izole edelim
                  try {
                    await quizProvider.resetAllProgress();
                    isCompleted = true;
                  } catch (e) {
                    print('QuizProvider resetAllProgress hatası: $e');
                    isCompleted = false;
                    rethrow;
                  }
                  
                  // İşlem başarılı - Loading dialog'u kapat
                  if (context.mounted) {
                    Navigator.of(loadingDialogContext).pop();
                    
                    // Başarılı dialog'unu göster
                    if (context.mounted) {
                      _showResetSuccessDialog(context);
                    }
                    
                    // Uygulamayı tamamen yeniden başlat
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      // Önce provider'ları sıfırla
                      try {
                        await Provider.of<QuizProvider>(context, listen: false).init();
                        Provider.of<AppProvider>(context, listen: false).resetState();

                        // Tüm route stack'i temizleyerek ana sayfaya yönlendir
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const HomePage()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        print('Provider sıfırlama hatası: $e');
                      }
                    });
                  }
                } catch (e) {
                  print('Reset hatası: $e');
                  
                  // Hata durumu - Loading dialog'u kapat
                  if (context.mounted && loadingDialogContext != null) {
                    try {
                      Navigator.of(loadingDialogContext).pop();
                    } catch (dialogError) {
                      print('Dialog kapatma hatası: $dialogError');
                    }
                    
                    if (context.mounted) {
                      try {
                        CustomSnackbar.showError(
                          context,
                          'İlerleme sıfırlanırken bir hata oluştu. Lütfen daha sonra tekrar deneyin.'
                        );
                      } catch (snackbarError) {
                        print('Snackbar gösterme hatası: $snackbarError');
                      }
                    }
                  }
                }
              },
              child: Text(
                'Sıfırla',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Sıfırlama başarılı dialog'u
  void _showResetSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade700,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade700.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başarılı ikonu
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                // Başlık
                Text(
                  'İşlem Başarılı',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Mesaj
                Text(
                  'İlerlemeniz başarıyla sıfırlandı. Uygulama yeni yüklenmiş gibi ayarlandı.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // Tamam butonu
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tamam',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
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
  
  Widget _buildDataItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ayarlar',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Ses Ayarları
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Ses',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                isSoundEnabled = !isSoundEnabled;
                              });
                              _saveSoundState();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                  if (!isSoundEnabled)
                                    Transform.rotate(
                                      angle: -0.785398, // 45 derece
                                      child: Container(
                                        width: 28,
                                        height: 2,
                                        color: Colors.blue.shade700,
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
                const SizedBox(height: 16),
                
                // Premium Paket
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade50,
                        Colors.blue.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Premium paket satın alma işlemi
                        Navigator.of(dialogContext).pop();
                        _showPremiumPackageDialog(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.workspace_premium,
                                color: Colors.amber.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Premium Paket',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'İNDİRİM',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reklamları kaldırın ve sınırsız haklara sahip olun',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // İlerlemeyi Sıfırla
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _showResetConfirmationDialog();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.refresh,
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
                                    'İlerlemeyi Sıfırla',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tüm verilerinizi silip baştan başlayın',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sürüm Bilgisi
                Center(
                  child: Text(
                    'Sürüm 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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

  Future<void> _showPremiumPackageDialog(BuildContext context) async {
    // Premium servisi context'inden alalım
    final premiumService = Provider.of<PremiumService>(context, listen: false);
    
    // Ürünleri önceden yükle, böylece dialog açıldığında hazır olurlar
    try {
      // Ürünleri yükle (snack alert göstermeden)
      await premiumService.loadProducts();
      
      // Eğer ürün bulunamadı hatası varsa göster
      if (premiumService.purchaseError != null) {
        if (context.mounted) {
          CustomSnackbar.showWarning(
            context,
            premiumService.purchaseError!
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.showError(
          context,
          'Premium ürünleri yüklenirken hata oluştu: $e'
        );
      }
    }
    
    // Dialog'u göster (eğer context hala geçerliyse)
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Builder(
            builder: (builderContext) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A237E), // Koyu lacivert
                      const Color(0xFF283593), // Lacivert
                      const Color(0xFF303F9F), // Mavi
                      const Color(0xFF3949AB), // Açık mavi
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade900.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Başlık
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: Colors.amber,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Premium',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Premium Özellikleri
                    ...List.generate(
                      3,
                      (index) {
                        IconData icon;
                        String title;
                        
                        switch (index) {
                          case 0:
                            icon = Icons.block;
                            title = 'Reklamları Kaldırın';
                            break;
                          case 1:
                            icon = Icons.favorite;
                            title = 'Sınırsız Can Hakkı';
                            break;
                          case 2:
                            icon = Icons.credit_card;
                            title = 'Sınırsız Kart Hakkı';
                            break;
                          default:
                            icon = Icons.star;
                            title = 'Premium Özellik';
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFFFC107),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Fiyat ve Satın Al Butonu
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Modern şerit indirim etiketi
                          Positioned(
                            top: -15,
                            right: -15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '%50',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'İNDİRİM',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // İçerik
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 10), // Etiket için biraz boşluk
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // İndirimli fiyat
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '₺',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Consumer<PremiumService>(
                                            builder: (_, premiumServiceConsumer, __) {
                                              String price = premiumServiceConsumer.premiumProduct?.price ?? '49,99';
                                              // TL ve ₺ işaretlerini kaldır
                                              price = price.replaceAll('TL', '').replaceAll('₺', '').trim();
                                              return Text(
                                                price,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      // Normal fiyat
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '99,90 TL',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(0.8),
                                            decoration: TextDecoration.lineThrough,
                                            decorationColor: Colors.white.withOpacity(0.8),
                                            decorationThickness: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Consumer<PremiumService>(
                                builder: (_, premiumServiceConsumer, __) {
                                  return ElevatedButton(
                                    onPressed: premiumServiceConsumer.isAvailable 
                                      ? () async {
                                        // Satın alma işlemini başlat (snack alert göstermeden)
                                        Navigator.of(dialogContext).pop();
                                        
                                        try {
                                          await premiumServiceConsumer.buyPremium();
                                        } catch (e) {
                                          // Hata oluşursa bildir - ana context kullan
                                          if (context.mounted) {
                                            CustomSnackbar.showError(
                                              context,
                                              'Satın alma işlemi sırasında bir hata oluştu: $e'
                                            );
                                          }
                                        }
                                      } 
                                      : null, // Eğer ürün mevcut değilse butonu devre dışı bırak
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFC107), // Parlak sarı/altın rengi
                                      foregroundColor: Colors.black87,
                                      disabledBackgroundColor: Colors.grey,
                                      disabledForegroundColor: Colors.black45,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 4,
                                      shadowColor: Colors.amber.withOpacity(0.5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          premiumServiceConsumer.isAvailable 
                                            ? 'Hemen Satın Al' 
                                            : 'Ürün Şu Anda Kullanılamıyor',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Satın Almaları Geri Yükleme Butonu
                    Consumer<PremiumService>(
                      builder: (_, premiumServiceConsumer, __) {
                        return Center(
                          child: TextButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              
                              try {
                                await premiumServiceConsumer.restorePurchases();
                                if (context.mounted) {
                                  CustomSnackbar.showSuccess(
                                    context,
                                    'Satın almalarınız başarıyla geri yüklendi!'
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  CustomSnackbar.showError(
                                    context,
                                    'Satın almalarınız geri yüklenirken bir hata oluştu: $e'
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.restore,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Satın Almalarımı Geri Yükle',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Not
                    Text(
                      'Tek seferlik ödeme. Abonelik değildir.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        if (!quizProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2C3E50),
                  const Color(0xFF34495E),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Premium göstergesi - Sadece premium kullanıcılara gösterilir
                        _buildPremiumBadge(),
                        Text(
                          'Learn English',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildOptionCard(
                                context: context,
                                title: 'Learn',
                                icon: Icons.school,
                                color: Colors.orange,
                                category: 'learn',
                              ),
                              const SizedBox(height: 24),
                              _buildOptionCard(
                                context: context,
                                title: 'Practice',
                                icon: Icons.psychology,
                                color: Colors.green,
                                category: 'practice',
                              ),
                              const SizedBox(height: 24),
                              // Reklam kartı
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                height: 180,
                                child: const ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                  child: NativeAdWidget(
                                    height: 180,
                                    margin: 0,
                                    factoryId: 'homePageNativeAd',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  isSoundEnabled = !isSoundEnabled;
                                });
                                _saveSoundState();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    if (!isSoundEnabled)
                                      Transform.rotate(
                                        angle: -0.785398, // 45 derece
                                        child: Container(
                                          width: 28,
                                          height: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showSettingsDialog(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
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
      },
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String category,
  }) {
    return CustomCard(
      elevation: 4,
      backgroundColor: Colors.white,
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        context.read<AppProvider>().setCategory(category);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LevelSelectionPage(category: category),
            ),
          );
      },
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: color,
            ),
          ),
          const SizedBox(width: 24),
          CustomCardTitle(
            text: title,
            fontSize: 24,
            color: color,
          ),
        ],
      ),
    );
  }

  // Premium başarı popup'ını göster
  void _showPremiumSuccessPopup() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PremiumSuccessPopup(
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  // Premium rozet widget'ı
  Widget _buildPremiumBadge() {
    return Consumer<PremiumService>(
      builder: (context, premiumService, _) {
        if (!premiumService.isPremium) {
          return const SizedBox(height: 150);
        }
        
        return Column(
          children: [
            Row(
              children: [
                // Şık premium rozet - arkaplan olmadan
                GestureDetector(
                  onTap: _showPremiumInfoDialog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 22,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium',
                        style: GoogleFonts.raleway(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 110), // Premium rozet ile toplam yükseklik yine 150 olacak
          ],
        );
      }
    );
  }

  // Premium bilgi dialogu
  void _showPremiumInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A148C), // Koyu mor
                  const Color(0xFF6A1B9A), // Mor
                  const Color(0xFF7B1FA2), // Mor-pembe
                  const Color(0xFF8E24AA), // Açık mor
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade900.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Premium Özellikler',
                        style: GoogleFonts.raleway(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Premium özellikleri
                _buildPremiumFeatureItem(
                  icon: Icons.block,
                  title: 'Reklamlar Kaldırıldı',
                  description: 'Tüm uygulamada reklam gösterilmez',
                ),
                const SizedBox(height: 10),
                _buildPremiumFeatureItem(
                  icon: Icons.all_inclusive,
                  title: 'Sınırsız Kullanım',
                  description: 'Can ve kart haklarında sınırlama yok',
                ),
                const SizedBox(height: 10),
                _buildPremiumFeatureItem(
                  icon: Icons.star,
                  title: 'Özel İçerikler',
                  description: 'Tüm premium içeriklere erişim',
                ),
                
                const SizedBox(height: 20),
                // Kapat butonu
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Tamam',
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade800,
                      ),
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
  
  // Premium özellik satırı widget'ı
  Widget _buildPremiumFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 