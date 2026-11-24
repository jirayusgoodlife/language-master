import 'package:flutter/material.dart';
import '../../../core/services/ollama_service.dart';
import '../../../core/services/tts_service.dart';
import 'settings_screen.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OllamaService _ollamaService = OllamaService();

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'こんにちは！ (Konnichiwa!) สวัสดีครับ ผมเป็น AI ติวเตอร์ภาษาญี่ปุ่นส่วนตัวของคุณ (รันบนโมเดล gemma4:31b)\n\nคุณสามารถ:\n1. ลองพิมพ์คุยเป็นภาษาญี่ปุ่น หรือพิมพ์ไทยถามได้เลย\n2. พิมพ์ประโยคที่อยากตรวจ หรือขอให้แต่งบทสนทนา\n3. ถามว่าควรเรียนเรื่องอะไรต่อดีตามระดับของคุณครับ!'
    }
  ];

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    _scrollToBottom();

    // Prepare system prompt for tutor persona
    final promptMessages = [
      {
        'role': 'system',
        'content': '''คุณเป็นครูสอนภาษาญี่ปุ่นและภาษาอังกฤษส่วนตัวที่มีความรู้ความเข้าใจผู้เรียนชาวไทยเป็นอย่างดี
- ใช้ภาษาไทยในการอธิบายไวยากรณ์และความหมาย เพื่อให้คนไม่มีพื้นฐานเข้าใจได้ง่าย
- ถ้าผู้เรียนพิมพ์ภาษาญี่ปุ่นมา ให้ชม แนะนำจุดที่ถูกต้อง และแก้ไขคำที่ผิดให้เป็นธรรมชาติ พร้อมใส่คำอ่าน Romaji และคำแปลภาษาไทยเสมอ
- ถ้าผู้เรียนถามว่าควรเรียนอะไรต่อ ให้อ้างอิงจากลำดับ: 1. จำตัวอักษรและรูปปากสระ -> 2. Shadowing วลีชีวิตประจำวัน NHK -> 3. คำศัพท์ N5 -> 4. แต่งประโยค
- สุภาพ เป็นกันเอง มีความเข้าใจและส่งเสริมการเรียนรู้เฉพาะบุคคล'''
      },
      ..._messages.map((m) => {
        'role': m['role']!,
        'content': m['content']!,
      })
    ];

    final reply = await _ollamaService.chat(messages: promptMessages);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Tutor (${_ollamaService.defaultModel})', style: const TextStyle(fontSize: 16)),
            Text(_ollamaService.baseUrl, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'ตั้งค่า LLM Server',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              setState(() {});
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final content = msg['content'] ?? '';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF6A1B9A) : Colors.purple.shade50,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      border: isUser ? null : Border.all(color: Colors.purple.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.volume_up, size: 18, color: Color(0xFF6A1B9A)),
                              onPressed: () => TtsService().speakJapanese(content),
                              tooltip: 'อ่านออกเสียง',
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('AI กำลังคิดคำแนะนำ...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'ถาม AI เช่น "ตรวจประโยคนี้ให้หน่อย" หรือคุยญี่ปุ่น...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
