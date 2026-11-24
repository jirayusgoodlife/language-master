import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OllamaService {
  static final OllamaService _instance = OllamaService._internal();
  factory OllamaService() => _instance;
  OllamaService._internal();

  static const String _keyServerUrl = 'ollama_server_url';
  static const String _keyModelName = 'ollama_model_name';

  String _baseUrl = 'http://10.80.39.43:11434';
  String _defaultModel = 'gemma4:31b';
  bool _isLoaded = false;

  String get baseUrl => _baseUrl;
  String get defaultModel => _defaultModel;

  Future<void> init() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyServerUrl) ?? 'http://10.80.39.43:11434';
    _defaultModel = prefs.getString(_keyModelName) ?? 'gemma4:31b';
    _isLoaded = true;
  }

  Future<void> updateConfig({required String baseUrl, required String modelName}) async {
    _baseUrl = baseUrl.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
    _defaultModel = modelName.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, _baseUrl);
    await prefs.setString(_keyModelName, _defaultModel);
  }

  Future<List<String>> fetchAvailableModels({String? customUrl}) async {
    final targetUrl = customUrl ?? _baseUrl;
    try {
      final response = await http
          .get(Uri.parse('$targetUrl/v1/models'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = data['data'] as List? ?? [];
        return list.map((e) => e['id'].toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<String> chat({
    required List<Map<String, String>> messages,
    String? model,
    int maxTokens = 500,
  }) async {
    await init();
    final targetModel = model ?? _defaultModel;
    final url = Uri.parse('$_baseUrl/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': targetModel,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        if (content.toString().trim().isNotEmpty) {
          return content.toString();
        }
        final reasoning = data['choices']?[0]?['message']?['reasoning'];
        if (reasoning != null) {
          return reasoning.toString();
        }
        return 'ไม่สามารถรับข้อความตอบกลับได้';
      } else {
        return 'Ollama Error: Status ${response.statusCode}';
      }
    } catch (e) {
      return 'เชื่อมต่อกับ AI Server ไม่ได้ ($_baseUrl): กรุณาตรวจสอบการตั้งค่า URL และเครือข่าย ($e)';
    }
  }

  Future<String> evaluateSentence({
    required String targetSentence,
    required String userTranslationOrInput,
    required String targetLanguage,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': '''คุณเป็นครูสอนภาษา $targetLanguage ใจดีสำหรับคนไทย
หน้าที่ของคุณ: ตรวจสอบประโยคที่ผู้เรียนแต่ง หรือวิเคราะห์ความถูกต้องของการพูด/แปล
- ให้คะแนน (เต็ม 10)
- ชี้จุดที่ถูกต้อง
- ชี้จุดที่ควรปรับปรุง (เช่น ไวยากรณ์, การออกเสียง, การเลือกใช้คำ)
- แนะนำทางเลือกที่เป็นธรรมชาติที่คนเจ้าของภาษาใช้จริง
ตอบสั้นกระชับเข้าใจง่าย เป็นกำลังใจให้ผู้เรียน''',
      },
      {
        'role': 'user',
        'content': '''โจทย์หรือประโยคเป้าหมาย: "$targetSentence"
สิ่งที่ผู้เรียนตอบ/แต่ง: "$userTranslationOrInput"

ช่วยวิเคราะห์และให้คำแนะนำอย่างละเอียดหน่อยครับ''',
      }
    ];

    return chat(messages: messages, maxTokens: 400);
  }
}
