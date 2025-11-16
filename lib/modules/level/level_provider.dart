import 'package:flutter/material.dart';

class LevelProvider extends ChangeNotifier {
  int _selectedLevel = 1;
  int get selectedLevel => _selectedLevel;

  void setLevel(int level) {
    _selectedLevel = level;
    notifyListeners();
  }

  bool isLevelLocked(int level) {
    return level > 1; // Şimdilik sadece 1. seviye açık
  }
} 