import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.45); // Slower speech for beginners
      _isInitialized = true;
    } catch (e) {
      // In web or restricted environments, fallback gracefully
    }
  }

  Future<void> speakJapanese(String text) async {
    await init();
    try {
      await _flutterTts.setLanguage('ja-JP');
      await _flutterTts.speak(text);
    } catch (e) {
      // fallback
    }
  }

  Future<void> speakEnglish(String text) async {
    await init();
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(text);
    } catch (e) {
      // fallback
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
