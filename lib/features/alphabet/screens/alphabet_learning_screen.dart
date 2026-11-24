import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/tts_service.dart';
import '../models/kana_char.dart';
import '../widgets/mouth_shape_widget.dart';
import 'writing_practice_screen.dart';

class AlphabetLearningScreen extends StatefulWidget {
  final String initialAlphabetType; // 'hiragana' or 'katakana'

  const AlphabetLearningScreen({super.key, this.initialAlphabetType = 'hiragana'});

  @override
  State<AlphabetLearningScreen> createState() => _AlphabetLearningScreenState();
}

class _AlphabetLearningScreenState extends State<AlphabetLearningScreen> {
  List<KanaChar> _characters = [];
  bool _isLoading = true;
  late String _alphabetType;
  final String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _alphabetType = widget.initialAlphabetType;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final path = _alphabetType == 'katakana'
          ? 'assets/data/japanese/katakana.json'
          : 'assets/data/japanese/hiragana.json';
      final jsonStr = await rootBundle.loadString(path);
      final List list = jsonDecode(jsonStr);
      setState(() {
        _characters = list.map((e) => KanaChar.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _switchAlphabet(String type) {
    if (_alphabetType == type) return;
    setState(() => _alphabetType = type);
    _loadData();
  }

  void _showMouthGuideDialog(KanaChar item) {
    TtsService().speakJapanese(item.char);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.char,
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Romaji: ${item.romaji}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'เสียงไทย: ${item.thai}',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    iconSize: 32,
                    onPressed: () => TtsService().speakJapanese(item.char),
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                ],
              ),
              const Divider(height: 32),
              // Mouth shape illustration & Phonics tips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MouthShapeWidget(lipOpening: item.mouthGuide.lipOpening, size: 100),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '👄 ${item.mouthGuide.shapeName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.mouthGuide.instruction,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'เทคนิคจำสำหรับคนไทย: ${item.mouthGuide.thaiApproximation}',
                        style: TextStyle(fontSize: 13, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.exampleWord != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.grey.shade900, fontSize: 13),
                            children: [
                              const TextSpan(text: 'คำศัพท์: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: '${item.exampleWord!.word} (${item.exampleWord!.reading}) = ${item.exampleWord!.meaning}'),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 20),
                        onPressed: () => TtsService().speakJapanese(item.exampleWord!.reading),
                      )
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WritingPracticeScreen(
                              initialChar: item,
                              sourceDataset: _alphabetType,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('ฝึกเขียนตัวนี้'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check),
                      label: const Text('เข้าใจแล้ว'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filtered = _selectedCategory == 'all'
        ? _characters
        : _characters.where((c) => c.category == _selectedCategory).toList();

    final title = _alphabetType == 'katakana'
        ? 'ตารางตัวอักษร คาตากานะ (Katakana)'
        : 'ตารางตัวอักษร ฮิรางานะ (Hiragana)';
    final primaryColor = _alphabetType == 'katakana' ? const Color(0xFFC2185B) : const Color(0xFFD32F2F);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'ฝึกเขียนตัวอักษร',
            icon: const Icon(Icons.edit_note, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WritingPracticeScreen(sourceDataset: _alphabetType),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'ฟังคำอธิบายทั้งหมด',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('แตะที่ตัวอักษรเพื่อฟังเสียง และดูรูปปากการขยับได้ทันทีโดยไม่ต้องต่อเน็ต')),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Alphabet Type Switcher (Hiragana vs Katakana)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('ฮิรางานะ (Hiragana)'),
                  selected: _alphabetType == 'hiragana',
                  selectedColor: Colors.red.shade100,
                  onSelected: (val) {
                    if (val) _switchAlphabet('hiragana');
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('คาตากานะ (Katakana)'),
                  selected: _alphabetType == 'katakana',
                  selectedColor: Colors.pink.shade100,
                  onSelected: (val) {
                    if (val) _switchAlphabet('katakana');
                  },
                ),
              ],
            ),
          ),
          // Instructions banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Color(0xFFD32F2F)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'แตะการ์ดตัวอักษรเพื่อฟังเสียงชัดเจน และเปิดดูการขยับปากออกเสียงแบบคนญี่ปุ่นแท้ๆ',
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return InkWell(
                  onTap: () => _showMouthGuideDialog(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.char,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.romaji,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${item.thai})',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('👄 รูปปาก', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
