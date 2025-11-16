import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  Timer? _timer;

  TextToSpeechService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    
    // Google TTS motorunu seç
    var engines = await _flutterTts.getEngines;
    for (var engine in engines) {
      if (engine.contains("google")) {
        await _flutterTts.setEngine(engine);
        break;
      }
    }

    // Ses kalitesi ayarları
    await _flutterTts.setVoice({
      "name": "en-us-x-tpf-local",
      "locale": "en-US"
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      _isSpeaking = false;
    });
  }

  Future<void> speakWord(String word, {String? audioUrl}) async {
    if (_isSpeaking) {
      await stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    _isSpeaking = true;
    await _flutterTts.speak(word);
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    stop();
    _flutterTts.stop();
  }
} 