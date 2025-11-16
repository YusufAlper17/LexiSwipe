# Premium Özellikler Entegrasyonu

Bu dokümanda, UFYO Sınav uygulamasına eklenen premium özelliklerin nasıl entegre edildiği ve kullanıldığı açıklanmaktadır.

## Genel Bakış

Premium paket, kullanıcılara aşağıdaki avantajları sağlamaktadır:

1. **Reklamları Kaldırma**: Premium kullanıcılar hiçbir reklam görmezler
2. **Sınırsız Can Hakkı**: Premium kullanıcılar can limiti olmadan sınırsız sınav çözebilirler
3. **Sınırsız Kart Hakkı**: Premium kullanıcılar kart limiti olmadan sınırsız kelime kartı kullanabilirler

## Teknik Entegrasyon

### 1. Kullanılan Paketler

- **in_app_purchase**: ^3.1.13 - Flutter in-app satın alma paketi

### 2. Dosya Yapısı

Premium özellikler aşağıdaki dosyalarda entegre edilmiştir:

- `lib/services/premium_service.dart`: Premium durumunu yöneten ana servis
- `lib/modules/quiz/quiz_provider.dart`: Premium durumuna göre can ve kart kullanımını yöneten kod
- `lib/services/ad_service.dart`: Premium durumuna göre reklam gösterimini yöneten kod
- `lib/widgets/hearts_indicator.dart`: Premium durumunu görsel olarak gösteren widget
- `lib/widgets/cards_indicator.dart`: Premium durumunu görsel olarak gösteren widget

### 3. Premium Servisi

PremiumService sınıfı, premium durumunu yönetmek için bir singleton olarak tasarlanmıştır. Bu servis:

- Premium durumunu SharedPreferences'da saklar
- In-App Purchase ile iletişim kurar
- Satın alma işlemlerini yönetir
- Premium durumunu diğer servislere sağlar

```dart
// Örnek kullanım
final premiumService = Provider.of<PremiumService>(context);
if (premiumService.isPremium) {
  // Premium özellikler aktif
} else {
  // Premium özellikler pasif
}
```

### 4. Uygulama İçi Satın Alma

Premium paket, Google Play ve App Store'da aşağıdaki ürün kimlikleriyle yapılandırılmıştır:

- **Ürün Kimliği**: `com.nexora.ufyo.premiumm`
- **Ürün Tipi**: Non-consumable (tüketilemeyen)
- **Fiyat**: 49.99 TL

## Geliştirici Notları

### Debug Modu

Debug modunda premium özelliklerini test etmek için, menüden "Premium Durumunu Değiştir (DEBUG)" seçeneği kullanılabilir. Bu seçenek sadece `kDebugMode` aktifken görünür.

### Google Play Console Yapılandırması

Google Play Console'da şu adımları tamamlamanız gerekir:

1. Play Console > Uygulamanız > Tüm uygulamalar > Ürünler > In-app ürünleri'ne gidin
2. "Ürün ekle" > "Tüketilmeyen" seçeneğini seçin
3. Ürün kimliği olarak `com.nexora.ufyo.premium` girin
4. Başlık, açıklama ve fiyat bilgilerini doldurun
5. Ürünü aktif edin

### App Store Connect Yapılandırması

App Store Connect'te şu adımları tamamlamanız gerekir:

1. App Store Connect > Uygulamanız > Özellikler > In-App Satın Almalar'a gidin
2. "+" butonuna tıklayın ve "Tüketilemeyen" seçeneğini seçin
3. Referans Adı olarak "Premium Paket" girin
4. Ürün Kimliği olarak `com.nexora.ufyo.premium` girin
5. Fiyat ve açıklama bilgilerini doldurun
6. Gözden geçirme bilgilerini doldurun ve ürünü aktif edin

## Kullanıcı Deneyimi

Premium kullanıcılar aşağıdaki görsel değişikliklerle ayırt edilirler:

1. Can göstergesinde "Premium" etiketi ve sonsuz işareti
2. Kart göstergesinde "Premium" etiketi ve sonsuz işareti
3. Reklamların tamamen kaldırılması
4. Video izle butonlarının gizlenmesi

## Satın Alma Akışı

1. Kullanıcı "Premium Paket" menü öğesine tıklar
2. Premium özelliklerin açıklandığı bir dialog gösterilir
3. Kullanıcı "Hemen Satın Al" butonuna tıklar
4. In-App Purchase akışı başlatılır
5. Ödeme başarılı olursa premium özellikler anında aktifleştirilir
6. Premium durumu cihazda saklanır ve uygulama yeniden başlatılsa bile korunur

## Önemli Notlar

- Premium özellikler cihaza özeldir, hesaba değil
- Kullanıcılar "Satın Almalarımı Geri Yükle" butonuyla önceki satın alımlarını geri yükleyebilirler
- Premium paket tek seferlik bir ödemedir, abonelik değildir 