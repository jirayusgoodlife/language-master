import 'package:flutter/material.dart';
import '../../../core/services/ollama_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final OllamaService _ollamaService = OllamaService();

  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;
  List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _ollamaService.init();
    _urlController.text = _ollamaService.baseUrl;
    _modelController.text = _ollamaService.defaultModel;
    _fetchModels(_urlController.text);
  }

  Future<void> _fetchModels(String url) async {
    final models = await _ollamaService.fetchAvailableModels(customUrl: url);
    if (mounted) {
      setState(() {
        _availableModels = models;
      });
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    final model = _modelController.text.trim();
    if (url.isEmpty || model.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final models = await _ollamaService.fetchAvailableModels(customUrl: url);
    if (models.isNotEmpty) {
      setState(() {
        _availableModels = models;
        _testSuccess = true;
        _testResult = 'เชื่อมต่อสำเร็จ! พบโมเดลทั้งหมด ${models.length} โมเดลในเครื่อง';
        _isTesting = false;
      });
    } else {
      setState(() {
        _testSuccess = false;
        _testResult = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ $url ได้ กรุณาตรวจสอบ IP หรือพอร์ต 11434';
        _isTesting = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final url = _urlController.text.trim();
    final model = _modelController.text.trim();
    if (url.isEmpty || model.isEmpty) return;

    await _ollamaService.updateConfig(baseUrl: url, modelName: model);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการตั้งค่า LLM Server เรียบร้อยแล้ว')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า LLM Server'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.dns, color: Color(0xFF6A1B9A), size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ollama / OpenAI-Compatible API',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF6A1B9A)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'กำหนด IP, Port และชื่อโมเดล AI ในเครือข่าย LAN หรือเครื่องของคุณเอง',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Server URL Field
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Server Base URL',
                hintText: 'http://10.80.39.43:11434',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => _fetchModels(val),
            ),
            const SizedBox(height: 16),

            // Model Selection / Field
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: 'ชื่อโมเดล (Model Name)',
                hintText: 'gemma4:31b',
                prefixIcon: const Icon(Icons.psychology),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // If detected models from server
            if (_availableModels.isNotEmpty) ...[
              const Text('เลือกโมเดลที่พบบนเซิร์ฟเวอร์:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableModels.map((m) {
                  final isSelected = _modelController.text == m;
                  return ChoiceChip(
                    label: Text(m, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _modelController.text = m);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Test Connection Button
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering),
              label: Text(_isTesting ? 'กำลังทดสอบการเชื่อมต่อ...' : 'ทดสอบการเชื่อมต่อ (Ping Server)'),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _testSuccess ? Colors.green : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(_testSuccess ? Icons.check_circle : Icons.error,
                        color: _testSuccess ? Colors.green : Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testSuccess ? Colors.green.shade900 : Colors.red.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('บันทึกการตั้งค่า'),
            ),

            const SizedBox(height: 30),

            // App Update & Version Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.system_update_rounded, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'การอัปเดตแอปพลิเคชัน (GitHub Auto Update)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: UpdateService().getCurrentAppVersion(),
                    builder: (context, snapshot) {
                      return Text(
                        'แอป: language 0 (เวอร์ชัน ${snapshot.data ?? "1.0.0"})',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Repository: jirayusgoodlife/language-master',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('ตรวจหาเวอร์ชันใหม่'),
                          onPressed: () async {
                            final scaffold = ScaffoldMessenger.of(context);
                            final info = await UpdateService().checkForUpdate(force: true);
                            if (!context.mounted) return;
                            if (info != null && info.isNewer) {
                              UpdateDialog.show(context, info);
                            } else {
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: const Text('คุณกำลังใช้งานเวอร์ชันล่าสุดแล้ว'),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'ล้างไฟล์ดาวน์โหลดที่ค้างอยู่',
                        icon: const Icon(Icons.cleaning_services_rounded, color: Colors.grey),
                        onPressed: () async {
                          await UpdateService().cleanLeftoverFiles();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ล้างไฟล์ติดตั้งชั่วคราวเรียบร้อยแล้ว')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
