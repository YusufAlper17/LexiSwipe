package com.nexora.lexiswipe

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class MainActivity: FlutterActivity() {
    // Factory ID'lerini tanımla
    private val factoryIds = listOf(
        "nativeAdFactory",
        "homePageNativeAd",
        "levelPageNativeAd", 
        "wordBankNativeAd",
        "examPageNativeAd",
        "mistakesPageNativeAd",
        "oxford3000NativeAd",
        "oxford5000NativeAd",
        "americanOxford3000NativeAd",
        "americanOxford5000NativeAd",
        "practiceOxford3000NativeAd",
        "practiceOxford5000NativeAd",
        "practiceAmericanOxford3000NativeAd",
        "practiceAmericanOxford5000NativeAd"
    )
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Her factory ID için NativeAdFactory kaydet
        factoryIds.forEach { factoryId ->
            GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine,
                factoryId,
                NativeAdFactoryImpl(context)
            )
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Her factory ID için NativeAdFactory kaldır
        factoryIds.forEach { factoryId ->
            GoogleMobileAdsPlugin.unregisterNativeAdFactory(
                flutterEngine,
                factoryId
            )
        }
        
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

// Native Ad Factory Implementasyonu
class NativeAdFactoryImpl(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        try {
            // Layout inflate et
            val adView = LayoutInflater.from(context)
                .inflate(R.layout.native_ad_layout, null) as NativeAdView

            // Reklam bileşenlerini al
            val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
            val bodyView = adView.findViewById<TextView>(R.id.ad_body)
            val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
            val callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action)
            val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
            // MediaView artık kullanılmıyor
            // val mediaView = adView.findViewById<com.google.android.gms.ads.nativead.MediaView>(R.id.ad_media)

            // Debug logları
            android.util.Log.d("NativeAdFactory", "Headline: ${nativeAd.headline}")
            android.util.Log.d("NativeAdFactory", "Body: ${nativeAd.body}")
            android.util.Log.d("NativeAdFactory", "CTA: ${nativeAd.callToAction}")
            android.util.Log.d("NativeAdFactory", "Advertiser: ${nativeAd.advertiser}")
            android.util.Log.d("NativeAdFactory", "Icon: ${nativeAd.icon?.drawable != null}")
            android.util.Log.d("NativeAdFactory", "MediaContent: ${nativeAd.mediaContent != null}")
            android.util.Log.d("NativeAdFactory", "HasVideoContent: ${nativeAd.mediaContent?.hasVideoContent() ?: false}")

            // Reklam verilerini yerleştir
            headlineView?.let {
                it.text = nativeAd.headline
                adView.headlineView = it
            }

            bodyView?.let {
                it.text = nativeAd.body
                adView.bodyView = it
            }

            callToActionView?.let {
                it.text = nativeAd.callToAction
                adView.callToActionView = it
            }
            
            advertiserView?.let {
                it.text = nativeAd.advertiser
                adView.advertiserView = it
            }

            // Icon için işlem
            iconView?.let {
                val icon = nativeAd.icon
                if (icon != null) {
                    it.setImageDrawable(icon.drawable)
                    adView.iconView = it
                }
            }
            
            // MediaView için işlem artık yapılmıyor
            /*
            mediaView?.let {
                adView.mediaView = it
            }
            */
            
            // NativeAd'ı adView'e kaydet
            adView.setNativeAd(nativeAd)
            
            return adView
        } catch (e: Exception) {
            android.util.Log.e("NativeAdFactory", "Reklam oluşturma hatası: ${e.message}", e)
            // Basit bir fallback view dön
            val fallbackView = LayoutInflater.from(context)
                .inflate(R.layout.native_ad_layout, null) as NativeAdView
            return fallbackView
        }
    }
} 