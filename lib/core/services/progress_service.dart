import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  static const String _keyCompletedKana = 'progress_completed_kana';
  static const String _keyCompletedShadowing = 'progress_completed_shadowing';
  static const String _keyCompletedQuizzes = 'progress_completed_quizzes';

  Future<Set<String>> getCompletedKana() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCompletedKana) ?? [];
    return list.toSet();
  }

  Future<void> markKanaLearned(String char) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCompletedKana();
    current.add(char);
    await prefs.setStringList(_keyCompletedKana, current.toList());
  }

  Future<Set<String>> getCompletedShadowing() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyCompletedShadowing) ?? [];
    return list.toSet();
  }

  Future<void> markShadowingCompleted(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCompletedShadowing();
    current.add(lessonId);
    await prefs.setStringList(_keyCompletedShadowing, current.toList());
  }

  Future<int> getQuizPassedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCompletedQuizzes) ?? 0;
  }

  Future<void> recordQuizScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyCompletedQuizzes) ?? 0;
    if (score > current) {
      await prefs.setInt(_keyCompletedQuizzes, score);
    }
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCompletedKana);
    await prefs.remove(_keyCompletedShadowing);
    await prefs.remove(_keyCompletedQuizzes);
  }
}
