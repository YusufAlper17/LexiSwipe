import 'package:flutter/material.dart';

enum Category {
  elementary,
  middle,
  high,
  adult,
}

class HomeProvider extends ChangeNotifier {
  Category? _selectedCategory;

  Category? get selectedCategory => _selectedCategory;

  void setCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }
} 