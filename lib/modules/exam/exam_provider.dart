import 'package:flutter/material.dart';

class ExamProvider extends ChangeNotifier {
  int? _selectedExam;
  int get selectedExam => _selectedExam ?? 1;

  void setExam(int exam) {
    _selectedExam = exam;
    notifyListeners();
  }

  final Set<int> _completedExams = {};

  bool isExamCompleted(int examNumber) {
    return _completedExams.contains(examNumber);
  }

  void markExamAsCompleted(int examNumber) {
    _completedExams.add(examNumber);
    notifyListeners();
  }
}

enum ExamStatus {
  completed,
  waiting
} 