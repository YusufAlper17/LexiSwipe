import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'premium_service.dart'; // Premium servisi ekledik

class AdService {
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial ID
    }
    return 'ca-app-pub-8106663637110231/4511624522'; // Gerçek Interstitial ID
  }
  
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test Rewarded Ad ID
    }
    return 'ca-app-pub-8106663637110231/9875315588'; // Gerçek Ödüllü Reklam ID
  }

  // Interstitial ad variables
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;
  static bool _isInterstitialAdLoading = false;
  static int _numInterstitialLoadAttempts = 0;
  static DateTime? _interstitialAdLoadTime;
  
  // Rewarded ad variables
  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdReady = false;
  static bool _isRewardedAdLoading = false;
  static int _numRewardedLoadAttempts = 0;
  static DateTime? _rewardedAdLoadTime;
  
  static int maxFailedLoadAttempts = 3;
  static const Duration adExpirationDuration = Duration(hours: 1);

  // Premium servis referansı
  static final PremiumService _premiumService = PremiumService();

  // Premium durumunu kontrol et - her seferinde güncel değeri al
  static bool get _isPremium => _premiumService.isPremium;

  // Reklamın süresi doldu mu kontrol et
  static bool _isAdExpired(DateTime? loadTime) {
    if (loadTime == null) return true;
    return DateTime.now().difference(loadTime) > adExpirationDuration;
  }

  // Ara reklam yükleme metodu
  static Future<bool> loadInterstitialAd() async {
    // Premium kullanıcılara reklam gösterme
    if (_isPremium) {
      debugPrint('Premium kullanıcı - reklam yüklenmeyecek');
      return false;
    }
    
    // Zaten yükleniyor ise bekle
    if (_isInterstitialAdLoading) return false;
    
    // Reklam hazır ve süresi dolmamışsa, yeniden yükleme
    if (_isInterstitialAdReady && _interstitialAd != null && !_isAdExpired(_interstitialAdLoadTime)) {
      return true;
    }
    
    _isInterstitialAdLoading = true;
    
    try {
      debugPrint('Geçiş reklamı yükleniyor...');
      
      // Mevcut reklamı temizle
      if (_interstitialAd != null) {
        _interstitialAd!.dispose();
        _interstitialAd = null;
      }
      
      // Ana thread'de reklam yükleme işlemini gerçekleştir
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            _isInterstitialAdLoading = false;
            _numInterstitialLoadAttempts = 0;
            _interstitialAdLoadTime = DateTime.now();
            debugPrint('Geçiş reklamı başarıyla yüklendi');

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Geçiş reklamı kapatıldı');
                _isInterstitialAdReady = false;
                ad.dispose();
                _interstitialAd = null;
                
                // Premium kullanıcısıysa yeniden yüklemeyi engelle
                if (!_isPremium) {
                  // Reklam gösterildikten sonra yeni bir reklam yükle
                  // Ana thread'de çalıştır
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    loadInterstitialAd();
                  });
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Geçiş reklamı gösterimi başarısız: $error');
                _isInterstitialAdReady = false;
                ad.dispose();
                _interstitialAd = null;
                
                // Premium kullanıcısıysa yeniden yüklemeyi engelle
                if (!_isPremium) {
                  // Ana thread'de çalıştır
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    loadInterstitialAd();
                  });
                }
              },
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Geçiş reklamı gösterildi');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Geçiş reklamı yüklenemedi: $error');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            _isInterstitialAdReady = false;
            _isInterstitialAdLoading = false;
            
            // onAdFailedToLoad içinde doğrudan yeniden yükleme yapmak yerine
            // durumu kaydet ve daha sonra bir kullanıcı etkileşimi veya
            // zamanlayıcı ile yeniden yükleme yap
            if (!_isPremium && _numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              // Yeniden yükleme işlemini geciktir
              Future.delayed(const Duration(seconds: 10), () {
                if (!_isPremium && !_isInterstitialAdLoading) {
                  debugPrint('Geçiş reklamı yeniden yükleniyor (deneme: $_numInterstitialLoadAttempts)');
                  // Ana thread'de çalıştır
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    loadInterstitialAd();
                  });
                }
              });
            }
          },
        ),
      );
      
      // Premium kullanıcısıysa beklemeden false dön
      if (_isPremium) {
        return false;
      }
      
      // Reklam yüklenene veya maksimum deneme sayısına ulaşana kadar bekle
      int attempts = 0;
      while (!_isInterstitialAdReady && attempts < 5) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }
      
      return _isInterstitialAdReady;
    } catch (e) {
      debugPrint('Reklam yükleme hatası: $e');
      _isInterstitialAdLoading = false;
      return false;
    }
  }

  static Future<bool> showInterstitialAd() async {
    // Premium kullanıcılara reklam gösterme
    if (_isPremium) {
      debugPrint('Premium kullanıcı - reklam gösterilmeyecek');
      return false;
    }
    
    // Reklamın süresi dolduysa yeniden yükle
    if (_isAdExpired(_interstitialAdLoadTime)) {
      _isInterstitialAdReady = false;
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
    
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      // Reklam hazır değilse yüklemeyi dene
      final isLoaded = await loadInterstitialAd();
      if (!isLoaded) return false;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        return true;
      } catch (e) {
        debugPrint('Reklam gösterme hatası: $e');
        return false;
      }
    }
    return false;
  }
  
  // Ödül reklamı yükleme metodu
  static Future<bool> loadRewardedAd() async {
    // Premium kullanıcıları reklamlardan muaf tut, ama ödülleri doğrudan al
    if (_isPremium) {
      debugPrint('Premium kullanıcı - ödül reklamı yüklenmeyecek');
      return true;
    }
    
    // Zaten yükleniyor ise bekle
    if (_isRewardedAdLoading) return false;
    
    // Reklam hazır ve süresi dolmamışsa, yeniden yükleme
    if (_isRewardedAdReady && _rewardedAd != null && !_isAdExpired(_rewardedAdLoadTime)) {
      return true;
    }
    
    _isRewardedAdLoading = true;
    
    try {
      debugPrint('Ödül reklamı yükleniyor...');
      
      // Mevcut reklamı temizle
      if (_rewardedAd != null) {
        _rewardedAd!.dispose();
        _rewardedAd = null;
      }
      
      // Ana thread'de reklam yükleme işlemini gerçekleştir
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _isRewardedAdLoading = false;
            _numRewardedLoadAttempts = 0;
            _rewardedAdLoadTime = DateTime.now();
            debugPrint('Ödül reklamı başarıyla yüklendi');

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Ödül reklamı kapatıldı');
                _isRewardedAdReady = false;
                ad.dispose();
                _rewardedAd = null;
                
                // Premium kullanıcısıysa yeniden yüklemeyi engelle
                if (!_isPremium) {
                  // Reklam gösterildikten sonra yeni bir reklam yükle
                  // Ana thread'de çalıştır
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    loadRewardedAd();
                  });
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Ödül reklamı gösterimi başarısız: $error');
                _isRewardedAdReady = false;
                ad.dispose();
                _rewardedAd = null;
                
                // Premium kullanıcısıysa yeniden yüklemeyi engelle
                if (!_isPremium) {
                  // Ana thread'de çalıştır
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    loadRewardedAd();
                  });
                }
              },
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Ödül reklamı gösterildi');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Ödül reklamı yüklenemedi: $error');
            _numRewardedLoadAttempts += 1;
            _rewardedAd = null;
            _isRewardedAdReady = false;
            _isRewardedAdLoading = false;
            
            // onAdFailedToLoad içinde doğrudan yeniden yükleme yapmak yerine
            // durumu kaydet ve daha sonra bir kullanıcı etkileşimi veya
            // zamanlayıcı ile yeniden yükleme yap
            if (!_isPremium && _numRewardedLoadAttempts < maxFailedLoadAttempts) {
              // Yeniden yükleme işlemini geciktir
              Future.delayed(const Duration(seconds: 10), () {
                if (!_isPremium && !_isRewardedAdLoading) {
                  debugPrint('Ödül reklamı yeniden yükleniyor (deneme: $_numRewardedLoadAttempts)');
                  // Ana thread'de çalıştır
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    loadRewardedAd();
                  });
                }
              });
            }
          },
        ),
      );
      
      // Premium kullanıcısıysa beklemeden true dön
      if (_isPremium) {
        return true;
      }
      
      // Reklam yüklenene veya maksimum deneme sayısına ulaşana kadar bekle
      int attempts = 0;
      while (!_isRewardedAdReady && attempts < 5) {
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }
      
      return _isRewardedAdReady;
    } catch (e) {
      debugPrint('Ödül reklamı yükleme hatası: $e');
      _isRewardedAdLoading = false;
      return false;
    }
  }

  // Ödül reklamı gösterme metodu
  static Future<bool> showRewardedAd({
    required Function onRewarded,
  }) async {
    // Premium kullanıcılara direkt ödül ver, reklam gösterme
    if (_isPremium) {
      debugPrint('Premium kullanıcı - direkt ödül verilecek');
      onRewarded();
      return true;
    }
    
    // Reklamın süresi dolduysa yeniden yükle
    if (_isAdExpired(_rewardedAdLoadTime)) {
      _isRewardedAdReady = false;
      _rewardedAd?.dispose();
      _rewardedAd = null;
    }
    
    if (!_isRewardedAdReady || _rewardedAd == null) {
      // Reklam hazır değilse yüklemeyi dene
      final isLoaded = await loadRewardedAd();
      if (!isLoaded) return false;
    }

    if (_isRewardedAdReady && _rewardedAd != null) {
      try {
        await _rewardedAd!.show(
          onUserEarnedReward: (_, reward) {
            debugPrint('Kullanıcı ödül kazandı: ${reward.amount} ${reward.type}');
            onRewarded();
          }
        );
        return true;
      } catch (e) {
        debugPrint('Ödül reklamı gösterme hatası: $e');
        return false;
      }
    }
    return false;
  }
  
  // Uygulama başladığında reklamları önceden yüklemek için
  static void preloadAds() {
    // Premium kullanıcılar için reklamları yükleme
    if (_isPremium) {
      debugPrint('Premium kullanıcı - reklamlar önceden yüklenmeyecek');
      return;
    }
    
    // Ana thread'de reklam yükleme işlemini gerçekleştir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInterstitialAd();
      loadRewardedAd();
    });
  }
  
  // Reklamları periyodik olarak yenile (1 saat sonra)
  static void refreshAdsIfNeeded() {
    if (_isPremium) return;
    
    // Reklamların süresi dolduysa yeniden yükle
    if (_isAdExpired(_interstitialAdLoadTime) && !_isInterstitialAdLoading) {
      debugPrint('Geçiş reklamının süresi doldu, yeniden yükleniyor...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadInterstitialAd();
      });
    }
    
    if (_isAdExpired(_rewardedAdLoadTime) && !_isRewardedAdLoading) {
      debugPrint('Ödül reklamının süresi doldu, yeniden yükleniyor...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadRewardedAd();
      });
    }
  }
  
  // Reklamları premium olmadan önce açılmış olabilecek tüm reklamları temizler
  static void clearAdsForPremiumUser() {
    if (_isPremium) {
      debugPrint('Premium kullanıcı - tüm reklamlar temizleniyor');
      
      // Interstitial reklamı temizle
      if (_interstitialAd != null) {
        _interstitialAd!.dispose();
        _interstitialAd = null;
        _isInterstitialAdReady = false;
      }
      
      // Rewarded reklamı temizle
      if (_rewardedAd != null) {
        _rewardedAd!.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
      }
    }
  }
} 