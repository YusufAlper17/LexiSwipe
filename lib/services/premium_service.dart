import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  // Premium durumu
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // In-App Purchase ile ilgili değişkenler
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Premium ürün ID'si - Google Play ve App Store'da aynı olmalı
  static const String _premiumProductId = 'com.nexora.lexiswipe.premiumm';
  // Play Store'daki ürün ID'leri listesi - ürün ID'lerini buraya ekleyin
  static const List<String> _productIds = ['com.nexora.lexiswipe.premiumm'];
  
  // Ürün bilgileri
  ProductDetails? _premiumProduct;
  ProductDetails? get premiumProduct => _premiumProduct;
  
  // Satın alma durumu
  String? _purchaseError;
  String? get purchaseError => _purchaseError;
  
  // Ürün durumu
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  // Yükleniyor durumu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    debugPrint('PremiumService initializing...');
    try {
      // Premium durumunu SharedPreferences'tan yükle
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('isPremium') ?? false;
      
      // In-App Purchase stream'ini dinle
      final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(_onPurchaseUpdate, onDone: _updateStreamOnDone, onError: _updateStreamOnError);
      
      // Ürünleri yükle
      await loadProducts();
      
      // Eğer premium satın alınmışsa, doğrulama yapalım
      if (_isPremium) {
        await _verifyPreviousPurchases();
      }
      
      debugPrint('PremiumService initialized successfully. Premium: $_isPremium');
    } catch (e) {
      debugPrint('PremiumService init error: $e');
    }
    
    notifyListeners();
  }

  Future<void> _verifyPreviousPurchases() async {
    try {
      // Geçmiş satın almaları doğrula
      // Not: purchaseStream zaten geçerli satın almaları bildirecek, ayrıca sorgulama yapmak gerekmeyebilir
      debugPrint('Önceki satın almaları kontrol ediyorum');
      
      // Önceki satın almalar purchaseStream içinde gelecektir
      // Bu sebeple burada sadece premium durumunu doğrulayalım
      final prefs = await SharedPreferences.getInstance();
      final isPremiumFromPrefs = prefs.getBool('isPremium') ?? false;
      
      if (isPremiumFromPrefs) {
        _isPremium = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Önceki satın almaları doğrularken hata: $e');
    }
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _purchaseError = null;
    notifyListeners();
    
    try {
      debugPrint('Ürünler yükleniyor...');
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        _isAvailable = false;
        _isLoading = false;
        _purchaseError = 'Mağaza bağlantısı kurulamadı';
        debugPrint('Mağaza bağlantısı kurulamadı');
        notifyListeners();
        return;
      }
      
      // Ürün bilgilerini al
      final ProductDetailsResponse productDetailsResponse = 
          await _inAppPurchase.queryProductDetails(_productIds.toSet());
      
      if (productDetailsResponse.error != null) {
        _isAvailable = false;
        _isLoading = false;
        _purchaseError = 'Ürün bilgileri alınamadı: ${productDetailsResponse.error}';
        debugPrint('Ürün bilgileri alınamadı: ${productDetailsResponse.error}');
        notifyListeners();
        return;
      }
      
      if (productDetailsResponse.productDetails.isEmpty) {
        _isAvailable = false;
        _isLoading = false;
        _purchaseError = 'Premium ürünü bulunamadı';
        debugPrint('Premium ürünü bulunamadı. Mağaza ürünleri boş geldi.');
        
        // Mağaza ile ilgili ek bilgiler - Future<bool> kontrolünü düzelt
        debugPrint('Google Play Billings durumu: Kontrol ediliyor...');
        _inAppPurchase.isAvailable().then((available) {
          debugPrint('Google Play Billings durumu: ${available ? 'Mevcut' : 'Mevcut Değil'}');
        });
        
        notifyListeners();
        return;
      }
      
      debugPrint('Bulunan ürünler: ${productDetailsResponse.productDetails.map((prod) => "${prod.id}: ${prod.price}").join(', ')}');
      
      // Premium ürününü bul
      for (final ProductDetails prod in productDetailsResponse.productDetails) {
        if (prod.id == _premiumProductId) {
          _premiumProduct = prod;
          debugPrint('Premium ürünü bulundu: ${prod.id} - ${prod.price}');
          break;
        }
      }
      
      _isAvailable = _premiumProduct != null;
      if (_isAvailable) {
        debugPrint('Premium ürünü hazır: ${_premiumProduct!.price}');
      } else {
        _purchaseError = 'Premium ürünü mağazada tanımlı değil';
        debugPrint('Premium ürünü mağazada tanımlı değil');
      }
    } catch (e) {
      _isAvailable = false;
      _purchaseError = 'Ürünler yüklenirken hata: $e';
      debugPrint('Ürünler yüklenirken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyPremium() async {
    if (_premiumProduct == null) {
      // Ürün yüklenemedi mi? Tekrar yüklemeyi dene
      await loadProducts();
      
      if (_premiumProduct == null) {
        _purchaseError = 'Premium ürünü bulunamadı';
        debugPrint('Premium ürünü bulunamadı');
        notifyListeners();
        return;
      }
    }
    
    try {
      _purchaseError = null;
      notifyListeners();
      
      // Satın alma işlemini başlat
      debugPrint('Premium satın alma başlatılıyor...');
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: _premiumProduct!);
      
      // Satın alma işlemine geçmeden önce ödeme sistemini kontrol et
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        _purchaseError = 'Ödeme sistemi şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';
        debugPrint('Ödeme sistemi kullanılamıyor');
        notifyListeners();
        return;
      }
      
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('Satın alma işlemi başlatıldı: $success');
      
      if (!success) {
        _purchaseError = 'Satın alma başlatılamadı. Lütfen daha sonra tekrar deneyin.';
        notifyListeners();
      }
    } catch (e) {
      _purchaseError = 'Satın alma başlatılırken hata: $e';
      debugPrint('Satın alma başlatılırken hata: $e');
      notifyListeners();
    }
  }
  
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Satın alma işlemi beklemede
        debugPrint('Satın alma işlemi beklemede');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Satın alma işlemi sırasında hata oluştu
        _purchaseError = 'Satın alma hatası: ${purchaseDetails.error?.message}';
        debugPrint('Satın alma hatası: ${purchaseDetails.error?.message}');
        notifyListeners();
      } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                 purchaseDetails.status == PurchaseStatus.restored) {
        // Satın alma işlemi tamamlandı veya geri yüklendi
        if (purchaseDetails.productID == _premiumProductId) {
          debugPrint('Premium satın alındı veya geri yüklendi');
          _activatePremium();
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint('Satın alma iptal edildi');
        _purchaseError = 'Satın alma iptal edildi';
        notifyListeners();
      }
      
      // Tamamlanan satın alma işlemleri için tamamlama işlemi yap
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint('Satın alma tamamlanıyor...');
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  void _updateStreamOnDone() {
    debugPrint('IAP stream tamamlandı');
    _subscription.cancel();
  }
  
  void _updateStreamOnError(error) {
    debugPrint('IAP stream hatası: $error');
    _purchaseError = 'Satın alma işlemi sırasında bir hata oluştu: $error';
    notifyListeners();
  }
  
  // Premium özelliklerini etkinleştir
  Future<void> _activatePremium() async {
    _isPremium = true;
    _purchaseError = null;
    
    // Premium durumunu kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', true);
    
    notifyListeners();
    debugPrint('Premium özellikler etkinleştirildi!');
  }
  
  // Önceki satın almaları geri yükle
  Future<void> restorePurchases() async {
    try {
      _purchaseError = null;
      notifyListeners();
      
      debugPrint('Önceki satın almalar geri yükleniyor...');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _purchaseError = 'Satın almaları geri yüklerken hata: $e';
      debugPrint('Satın almaları geri yüklerken hata: $e');
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
} 