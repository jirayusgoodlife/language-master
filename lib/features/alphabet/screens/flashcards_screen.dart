import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/tts_service.dart';

class FlashcardItem {
  final String id;
  final String word;
  final String? kanji;
  final String romaji;
  final String thai;
  final String category;
  final String example;

  FlashcardItem({
    required this.id,
    required this.word,
    this.kanji,
    required this.romaji,
    required this.thai,
    required this.category,
    required this.example,
  });

  factory FlashcardItem.fromJson(Map<String, dynamic> json) {
    return FlashcardItem(
      id: json['id'] ?? '',
      word: json['word'] ?? '',
      kanji: json['kanji'],
      romaji: json['romaji'] ?? '',
      thai: json['thai'] ?? '',
      category: json['category'] ?? '',
      example: json['example'] ?? '',
    );
  }
}

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<FlashcardItem> _cards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Set<String> _knownWordIds = {};

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/japanese/flashcards.json');
      final List list = jsonDecode(jsonStr);
      setState(() {
        _cards = list.map((e) => FlashcardItem.fromJson(e)).toList();
        _isLoading = false;
      });
      if (_cards.isNotEmpty) {
        _speakCurrent();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _speakCurrent() {
    if (_cards.isNotEmpty) {
      TtsService().speakJapanese(_cards[_currentIndex].word);
    }
  }

  void _nextCard(bool knewIt) {
    if (knewIt) {
      _knownWordIds.add(_cards[_currentIndex].id);
    }
    setState(() {
      _isFlipped = false;
      // Loop endlessly
      _currentIndex = (_currentIndex + 1) % _cards.length;
    });
    _speakCurrent();
  }

  void _prevCard() {
    setState(() {
      _isFlipped = false;
      _currentIndex = (_currentIndex - 1 + _cards.length) % _cards.length;
    });
    _speakCurrent();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cards.isEmpty) {
      return const Scaffold(body: Center(child: Text('ไม่พบข้อมูลคำศัพท์')));
    }

    final card = _cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('การ์ดจำคำศัพท์ (SRS Flashcards)'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'ฟังเสียงอ่าน',
            icon: const Icon(Icons.volume_up),
            onPressed: _speakCurrent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'การ์ดใบที่ ${_currentIndex + 1} / ${_cards.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        'จำได้แล้ว: ${_knownWordIds.length}/${_cards.length}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900, fontSize: 12),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _cards.length,
                color: const Color(0xFF00897B),
                backgroundColor: Colors.teal.shade100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            // Flippable Flashcard
            GestureDetector(
              onTap: () {
                setState(() => _isFlipped = !_isFlipped);
                if (_isFlipped) _speakCurrent();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 320),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isFlipped
                        ? [Colors.teal.shade700, Colors.teal.shade900]
                        : [Colors.white, Colors.teal.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isFlipped ? Colors.teal.shade600 : Colors.teal.shade200,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isFlipped ? '💡 เฉลย & ตัวอย่างประโยค' : '👆 แตะการ์ดเพื่อดูความหมาย',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isFlipped ? Colors.white70 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Front of card
                    if (!_isFlipped) ...[
                      Text(
                        card.word,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                      if (card.kanji != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'คันจิ: ${card.kanji}',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        card.romaji,
                        style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                      ),
                    ],

                    // Back of card (Flipped)
                    if (_isFlipped) ...[
                      Text(
                        card.thai,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.word,
                        style: const TextStyle(fontSize: 20, color: Colors.amberAccent, fontWeight: FontWeight.w600),
                      ),
                      const Divider(color: Colors.white24, height: 32),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ตัวอย่างประโยค:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              card.example,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Action Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => _nextCard(false),
                    icon: const Icon(Icons.close),
                    label: const Text('ยังจำไม่ได้'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: () => _nextCard(true),
                    icon: const Icon(Icons.check),
                    label: const Text('จำได้แล้ว!'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _prevCard,
              icon: const Icon(Icons.arrow_back),
              label: const Text('ย้อนกลับไปการ์ดใบก่อนหน้า'),
            ),
          ],
        ),
      ),
    );
  }
}
