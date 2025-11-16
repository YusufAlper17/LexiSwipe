import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_card.dart';
import '../../services/premium_service.dart';

class NativeAdWidget extends StatefulWidget {
  final double height;
  final double margin;
  final bool showPlaceholder;
  final String factoryId;
  final String? adUnitId;
  
  const NativeAdWidget({
    super.key,
    this.height = 180,
    this.margin = 0,
    this.showPlaceholder = true,
    this.factoryId = 'nativeAdFactory',
    this.adUnitId,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> with AutomaticKeepAliveClientMixin {
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;
  bool _isPremium = false;
  bool _hasError = false;
  bool _isLoading = false;
  int _loadAttempts = 0;
  final PremiumService _premiumService = PremiumService();
  
  // Reklam yükleme zaman damgası - 1 saat sonra yeniden yükleme için
  DateTime? _adLoadTimestamp;
  
  // Ad Unit ID'leri
  static const Map<String, String> _adUnitIds = {
    'nativeAdFactory': 'ca-app-pub-8106663637110231/9979257363',    // Varsayılan reklam ID'si
    'homePageNativeAd': 'ca-app-pub-8106663637110231/9979257363',   // Ana sayfa
    'levelPageNativeAd': 'ca-app-pub-8106663637110231/7274037121',  // Seviye sayfası
    'wordBankNativeAd': 'ca-app-pub-8106663637110231/8814349506',   // Kelime bankası
    'examPageNativeAd': 'ca-app-pub-8106663637110231/8590988220',   // Sınav sayfası
    'mistakesPageNativeAd': 'ca-app-pub-8106663637110231/4052977412', // Hatalar sayfası
    
    // Word List Kategorileri için Reklam ID'leri
    'oxford3000NativeAd': 'ca-app-pub-8106663637110231/7175363571',    // The Oxford 3000
    'oxford5000NativeAd': 'ca-app-pub-8106663637110231/7647002839',    // The Oxford 5000
    'americanOxford3000NativeAd': 'ca-app-pub-8106663637110231/3787648875', // American Oxford 3000
    'americanOxford5000NativeAd': 'ca-app-pub-8106663637110231/5020839493', // American Oxford 5000
    
    // Practice List için Reklam ID'leri
    'practiceOxford3000NativeAd': 'ca-app-pub-8106663637110231/6299333977',    // The Oxford 3000 Practice
    'practiceOxford5000NativeAd': 'ca-app-pub-8106663637110231/1161485536',    // The Oxford 5000 Practice
    'practiceAmericanOxford3000NativeAd': 'ca-app-pub-8106663637110231/6142349470', // American Oxford 3000 Practice
    'practiceAmericanOxford5000NativeAd': 'ca-app-pub-8106663637110231/1731465201', // American Oxford 5000 Practice
  };

  // Default Ad Unit ID - Eğer bir hata olursa bu ID kullanılacak
  static const String _defaultAdUnitId = 'ca-app-pub-8106663637110231/9979257363';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    if (!_isPremium) {
      // Ana thread'de reklam yükleme işlemini başlat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNativeAd();
      });
    }
    
    _premiumService.addListener(_onPremiumStatusChanged);
  }

  @override
  void dispose() {
    // Reklam kaynağını temizle
    if (_nativeAd != null) {
      _nativeAd!.dispose();
      _nativeAd = null;
    }
    _premiumService.removeListener(_onPremiumStatusChanged);
    super.dispose();
  }
  
  void _checkPremiumStatus() {
    setState(() {
      _isPremium = _premiumService.isPremium;
    });
  }
  
  void _onPremiumStatusChanged() {
    if (_premiumService.isPremium && _nativeAd != null) {
      _nativeAd!.dispose();
      _nativeAd = null;
      setState(() {
        _isNativeAdLoaded = false;
        _isPremium = true;
      });
    } 
    else if (!_premiumService.isPremium && _nativeAd == null) {
      setState(() {
        _isPremium = false;
      });
      // Ana thread'de reklam yükleme işlemini başlat
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNativeAd();
      });
    }
  }

  // Reklamın 1 saat içinde yüklenip yüklenmediğini kontrol et
  bool _shouldReloadAd() {
    if (_adLoadTimestamp == null) return true;
    
    final difference = DateTime.now().difference(_adLoadTimestamp!);
    return difference.inHours >= 1; // 1 saat geçtiyse yeniden yükle
  }

  void _loadNativeAd() {
    // Zaten yükleniyor veya premium kullanıcı ise yükleme
    if (_isLoading || _premiumService.isPremium) {
      return;
    }
    
    // Reklam zaten yüklenmişse ve 1 saat geçmediyse yeniden yükleme
    if (_isNativeAdLoaded && _nativeAd != null && !_shouldReloadAd()) {
      return;
    }
    
    _isLoading = true;
    
    try {
      setState(() {
        _hasError = false;
      });
      
      // Mevcut reklam varsa temizle
      if (_nativeAd != null) {
        _nativeAd!.dispose();
        _nativeAd = null;
      }
      
      final adUnitId = _adUnitIds[widget.factoryId] ?? _defaultAdUnitId;
      print('Native reklam yükleniyor... (${widget.factoryId})');
      print('AdUnitId: $adUnitId');
      
      _nativeAd = NativeAd(
        adUnitId: adUnitId,
        factoryId: widget.factoryId,
        request: const AdRequest(),
        // İlave parametreler ekleyerek reklam loadingini iyileştir
        nativeAdOptions: NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.topRightCorner,
          mediaAspectRatio: MediaAspectRatio.any,
          videoOptions: VideoOptions(
            startMuted: true,
            clickToExpandRequested: true,
          ),
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!_premiumService.isPremium) {
              setState(() {
                _isNativeAdLoaded = true;
                _loadAttempts = 0;
                _isLoading = false;
                _adLoadTimestamp = DateTime.now(); // Yükleme zamanını kaydet
              });
              print('Native reklam başarıyla yüklendi (${widget.factoryId})');
            } else {
              ad.dispose();
              _isLoading = false;
            }
          },
          onAdFailedToLoad: (ad, error) {
            print('Native reklam yüklenemedi (${widget.factoryId})');
            print('Hata mesajı: ${error.message}');
            print('Hata kodu: ${error.code}');
            print('Factory ID: ${widget.factoryId}');
            print('AdUnit ID: $adUnitId');
            
            ad.dispose();
            setState(() {
              _isNativeAdLoaded = false;
              _hasError = true;
              _isLoading = false;
            });
            
            // onAdFailedToLoad içinde doğrudan yeniden yükleme yapmak yerine
            // durumu kaydet ve daha sonra bir kullanıcı etkileşimi veya
            // zamanlayıcı ile yeniden yükleme yap
            if (!_premiumService.isPremium && _loadAttempts < 3) {
              _loadAttempts++;
              // Yeniden yükleme işlemini ana thread'e taşı ve geciktir
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted && !_premiumService.isPremium && !_isLoading) {
                  print('Yeniden yükleme denemesi $_loadAttempts/3');
                  // Ana thread'de çalıştır
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadNativeAd();
                  });
                }
              });
            }
          },
          onAdOpened: (ad) => print('Native reklam açıldı (${widget.factoryId})'),
          onAdClosed: (ad) => print('Native reklam kapatıldı (${widget.factoryId})'),
          onAdImpression: (ad) => print('Native reklam gösterildi (${widget.factoryId})'),
          onAdClicked: (ad) => print('Native reklama tıklandı (${widget.factoryId})'),
        ),
      );
      
      if (!_premiumService.isPremium) {
        _nativeAd!.load();
      } else {
        _isLoading = false;
      }
    } catch (e) {
      print('Reklam yükleme hatası (${widget.factoryId}): $e');
      setState(() {
        _isNativeAdLoaded = false;
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  // Görünürlük değiştiğinde reklamı yeniden yükle
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Eğer reklam 1 saat önce yüklendiyse ve premium kullanıcı değilse yeniden yükle
    if (!_isPremium && _shouldReloadAd() && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNativeAd();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_premiumService.isPremium) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.all(widget.margin),
      child: _isNativeAdLoaded && _nativeAd != null
          ? CustomCard(
              elevation: 4,
              backgroundColor: Colors.white,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(0),
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AdWidget(ad: _nativeAd!),
                ),
              ),
            )
          : widget.showPlaceholder 
              ? Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasError ? Icons.sync_problem : Icons.info_outline,
                          color: _hasError ? Colors.orange[700] : Colors.grey[500],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasError ? 'Yükleme hatası. Yeniden deneniyor...' : 'Reklam Yükleniyor...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _hasError ? Colors.orange[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
} 