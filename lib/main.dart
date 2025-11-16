import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/app_provider.dart';
import 'modules/quiz/quiz_provider.dart';
import 'core/theme/app_theme.dart';
import 'modules/home/home_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'widgets/text_to_speech_widget.dart';
import 'services/sound_service.dart';
import 'services/ad_service.dart';
import 'services/premium_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modules/onboarding/onboarding_page.dart';
import 'modules/level/level_selection_page.dart';
import 'dart:async';

void main() {
  // Flutter'ı başlat
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Flutter initialized');

  // Uygulamayı MultiProvider içinde başlat
  runApp(
    const InitializerWidget(),
  );
}

class InitializerWidget extends StatefulWidget {
  const InitializerWidget({super.key});

  @override
  State<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  late QuizProvider quizProvider;
  late PremiumService premiumService;
  bool isLoading = true;
  String? error;
  bool? hasCompletedOnboarding;
  Timer? _adRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _adRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('Starting initialization...');
      
      // Onboarding durumunu kontrol et
      final prefs = await SharedPreferences.getInstance();
      hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
      debugPrint('Onboarding completed: $hasCompletedOnboarding');
      
      // Ses servisini başlat
      try {
        await SoundService().init();
        debugPrint('SoundService initialized');
      } catch (e) {
        debugPrint('SoundService initialization error: $e');
      }
      
      // Premium servisi başlat
      premiumService = PremiumService();
      try {
        await premiumService.init();
        debugPrint('PremiumService initialized');
      } catch (e) {
        debugPrint('Error initializing PremiumService: $e');
      }
      
      // MobileAds'i başlat - Ana thread'de çalıştır
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Test cihazı ayarlarını kaldır ve üretim için yapılandır
          await MobileAds.instance.initialize();
          await MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(
              tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
              testDeviceIds: [], // Boş liste ile test cihazlarını kaldır
            ),
          );
          debugPrint('MobileAds initialized for production');
          
          // Önceden reklamları yükle
          AdService.preloadAds();
          debugPrint('Ads preloaded');
          
          // Reklamları periyodik olarak yenile (15 dakikada bir kontrol et)
          _adRefreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
            debugPrint('Checking ads for refresh...');
            AdService.refreshAdsIfNeeded();
          });
        });
      } catch (e) {
        debugPrint('Error initializing MobileAds: $e');
        // MobileAds hatası kritik değil, devam et
      }

      // QuizProvider'ı başlat
      quizProvider = QuizProvider();
      try {
        await quizProvider.init();
        debugPrint('QuizProvider initialized');
      } catch (e) {
        debugPrint('Error initializing QuizProvider: $e');
        // QuizProvider hatası kritik değil, devam et
      }

      // Başlatma tamamlandı
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Critical error during initialization: $e');
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Uygulama başlatılırken bir hata oluştu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        error = null;
                      });
                      _initialize();
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Tüm Provider'ları başlatma sonrası ekle, böylece erişilebilir olurlar
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider.value(value: quizProvider),
        ChangeNotifierProvider.value(value: premiumService),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'LexiSwipe - Oxford Vocabulary',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  SoundService().playClickSound();
                },
                child: hasCompletedOnboarding == true
                  ? const HomePage()
                  : const OnboardingPage(),
              ),
              '/level_selection': (context) => const LevelSelectionPage(category: 'practice'),
            },
            onGenerateRoute: (settings) {
              // Burada özel route'lar tanımlanabilir
              return null;
            },
          );
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İngilizce Kelime Seslendirici',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İngilizce Kelime Seslendirici'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: SingleChildScrollView(
          child: TextToSpeechWidget(),
        ),
      ),
    );
  }
} 