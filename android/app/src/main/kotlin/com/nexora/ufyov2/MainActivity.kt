package com.nexora.ufyov2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.content.Context
import android.view.LayoutInflater
import android.widget.TextView
import android.widget.ImageView
import android.widget.Button
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory
import android.view.View
import android.widget.RatingBar

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Native Ad factory'i kaydet
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "nativeAdFactory",
            NativeAdFactoryExample(context)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        
        // Temizleme sırasında factory'i kaldır
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "nativeAdFactory"
        )
    }
}

class NativeAdFactoryExample(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        // XML layout'u kullanarak NativeAdView oluştur
        val inflater = LayoutInflater.from(context)
        val packageName = context.packageName
        val layoutResId = context.resources.getIdentifier("native_ad_layout", "layout", packageName)
        val adView = inflater.inflate(layoutResId, null) as NativeAdView
        
        // Öğelerin ID'lerini al
        val headlineId = context.resources.getIdentifier("ad_headline", "id", packageName)
        val bodyId = context.resources.getIdentifier("ad_body", "id", packageName)
        val iconId = context.resources.getIdentifier("ad_app_icon", "id", packageName)
        val advertiserId = context.resources.getIdentifier("ad_advertiser", "id", packageName)
        val attributionId = context.resources.getIdentifier("ad_attribution", "id", packageName)
        val ctaId = context.resources.getIdentifier("ad_call_to_action", "id", packageName)
        val headerLayoutId = context.resources.getIdentifier("ad_header_layout", "id", packageName)
        
        // Reklam öğeleri için view'ları bul ve ayarla
        // 1. Başlık
        val headlineView = adView.findViewById<TextView>(headlineId)
        if (nativeAd.headline != null) {
            headlineView.text = nativeAd.headline
            headlineView.visibility = View.VISIBLE
        } else {
            headlineView.visibility = View.INVISIBLE
        }
        adView.headlineView = headlineView
        
        // 2. Açıklama
        val bodyView = adView.findViewById<TextView>(bodyId)
        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
        } else {
            bodyView.visibility = View.INVISIBLE
        }
        adView.bodyView = bodyView
        
        // 3. Uygulama İkonu
        val iconView = adView.findViewById<ImageView>(iconId)
        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon!!.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }
        adView.iconView = iconView
        
        // 4. Reklam Veren
        val advertiserView = adView.findViewById<TextView>(advertiserId)
        if (nativeAd.advertiser != null) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = View.VISIBLE
        } else {
            advertiserView.visibility = View.INVISIBLE
        }
        adView.advertiserView = advertiserView
        
        // 5. Eylem Çağrısı (CTA) Butonu
        val ctaView = adView.findViewById<Button>(ctaId)
        if (nativeAd.callToAction != null) {
            ctaView.text = nativeAd.callToAction
            ctaView.visibility = View.VISIBLE
        } else {
            ctaView.visibility = View.INVISIBLE
        }
        adView.callToActionView = ctaView
        
        // 6. Reklam etiketi
        val attributionView = adView.findViewById<TextView>(attributionId)
        if (attributionView != null) {
            attributionView.visibility = View.VISIBLE
        }
        
        // NativeAd'i görünümle ilişkilendir
        adView.setNativeAd(nativeAd)
        
        return adView
    }
}
