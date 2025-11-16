import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
  }

  Future<void> playClickSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/mixkit-cool-interface-click-tone-2568.wav'));
    } catch (e) {
      debugPrint('Error playing click sound: $e');
    }
  }

  Future<void> playCorrectSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/mixkit-correct-answer-tone-2870.wav'));
    } catch (e) {
      debugPrint('Error playing correct sound: $e');
    }
  }

  Future<void> playWrongSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/error-8-206492.mp3'));
    } catch (e) {
      debugPrint('Error playing wrong sound: $e');
    }
  }

  Future<void> playSwipeRightSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/swipe.mp3'));
    } catch (e) {
      debugPrint('Error playing swipe right sound: $e');
    }
  }

  Future<void> playSwipeLeftSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/swipe.mp3'));
    } catch (e) {
      debugPrint('Error playing swipe left sound: $e');
    }
  }

  Future<void> playFlipSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/cevirme.mp3'));
    } catch (e) {
      debugPrint('Error playing flip sound: $e');
    }
  }

  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
  }

  bool get isSoundEnabled => _isSoundEnabled;

  void dispose() {
    _audioPlayer.dispose();
  }
} 