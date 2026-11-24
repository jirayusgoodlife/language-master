import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _quizzes = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int? _selectedChoiceIndex;
  List<String> _userBuiltTokens = [];
  List<String> _availableTokens = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/japanese/quizzes.json');
      final list = jsonDecode(jsonStr);
      setState(() {
        _quizzes = list;
        _isLoading = false;
        _setupCurrentQuestion();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupCurrentQuestion() {
    _isAnswered = false;
    _selectedChoiceIndex = null;
    _userBuiltTokens = [];

    if (_quizzes.isNotEmpty && _currentIndex < _quizzes.length) {
      final q = _quizzes[_currentIndex];
      if (q['type'] == 'sentence_builder') {
        _availableTokens = List<String>.from(q['scrambledTokens']);
      }
    }
  }

  void _onAnswerChoice(int index) {
    if (_isAnswered) return;
    final q = _quizzes[_currentIndex];
    final isCorrect = index == q['correctIndex'];
    setState(() {
      _selectedChoiceIndex = index;
      _isAnswered = true;
      if (isCorrect) _score++;
    });
  }

  void _checkSentenceBuilder() {
    if (_isAnswered) return;
    final q = _quizzes[_currentIndex];
    final correctTokens = List<String>.from(q['correctTokens']);
    final isCorrect = _userBuiltTokens.join('') == correctTokens.join('');
    setState(() {
      _isAnswered = true;
      if (isCorrect) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentIndex >= _quizzes.length) {
      ProgressService().recordQuizScore(_score);
      return Scaffold(
        appBar: AppBar(title: const Text('ผลการทดสอบ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                const SizedBox(height: 16),
                const Text('ยอดเยี่ยมมาก! คุณทำแบบทดสอบจบแล้ว', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('คะแนนที่คุณได้: $_score / ${_quizzes.length}', style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _score = 0;
                      _setupCurrentQuestion();
                    });
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('ทำแบบทดสอบใหม่อีกครั้ง'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _quizzes[_currentIndex];
    final isSentenceBuilder = q['type'] == 'sentence_builder';

    return Scaffold(
      appBar: AppBar(
        title: Text('แบบทดสอบความจำ & ไวยากรณ์ (${_currentIndex + 1}/${_quizzes.length})'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _quizzes.length,
              color: Colors.green,
              backgroundColor: Colors.green.shade100,
            ),
            const SizedBox(height: 24),

            // Prompt Question Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    q['prompt'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (q['target'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      q['target'],
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.green),
                      onPressed: () => TtsService().speakJapanese(q['target']),
                    )
                  ],
                  if (isSentenceBuilder) ...[
                    const SizedBox(height: 10),
                    Text(
                      'โจทย์: "${q['targetThai']}"',
                      style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question Type 1: Multiple Choice
            if (!isSentenceBuilder) ...[
              ...List.generate((q['options'] as List).length, (idx) {
                final optionText = q['options'][idx];
                final isSelected = _selectedChoiceIndex == idx;
                final isCorrectOption = idx == q['correctIndex'];

                Color tileColor = Colors.white;
                BorderSide borderSide = BorderSide(color: Colors.grey.shade300);

                if (_isAnswered) {
                  if (isCorrectOption) {
                    tileColor = Colors.green.shade100;
                    borderSide = const BorderSide(color: Colors.green, width: 2);
                  } else if (isSelected) {
                    tileColor = Colors.red.shade100;
                    borderSide = const BorderSide(color: Colors.red, width: 2);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _isAnswered ? null : () => _onAnswerChoice(idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.fromBorderSide(borderSide),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Text(
                        optionText,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Question Type 2: Sentence Builder
            if (isSentenceBuilder) ...[
              // User assembled sentence display
              Container(
                constraints: const Duration(milliseconds: 100) > Duration.zero ? const BoxConstraints(minHeight: 80) : null,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                ),
                child: _userBuiltTokens.isEmpty
                    ? Center(
                        child: Text(
                          'แตะคำด้านล่างเพื่อต่อประโยคที่ถูกต้อง',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _userBuiltTokens.map((token) {
                          return ActionChip(
                            label: Text(token, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            onPressed: _isAnswered
                                ? null
                                : () {
                                    setState(() {
                                      _userBuiltTokens.remove(token);
                                      _availableTokens.add(token);
                                    });
                                  },
                            avatar: const Icon(Icons.remove_circle, size: 16, color: Colors.red),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),

              // Available scrambled tokens
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _availableTokens.map((token) {
                  return ActionChip(
                    label: Text(token, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.blue.shade50,
                    onPressed: _isAnswered
                        ? null
                        : () {
                            setState(() {
                              _availableTokens.remove(token);
                              _userBuiltTokens.add(token);
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (!_isAnswered)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: _userBuiltTokens.isNotEmpty ? _checkSentenceBuilder : null,
                  child: const Text('ตรวจคำตอบ'),
                ),
            ],

            // Explanation & Next Button when answered
            if (_isAnswered) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 คำอธิบาย:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(q['explanation'] ?? '', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex++;
                    _setupCurrentQuestion();
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('ข้อถัดไป'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
