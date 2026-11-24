import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/tts_service.dart';
import '../models/kanji_item.dart';
import '../models/kana_char.dart';
import 'writing_practice_screen.dart';

class KanjiLearningScreen extends StatefulWidget {
  const KanjiLearningScreen({super.key});

  @override
  State<KanjiLearningScreen> createState() => _KanjiLearningScreenState();
}

class _KanjiLearningScreenState extends State<KanjiLearningScreen> {
  List<KanjiItem> _kanjiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKanji();
  }

  Future<void> _loadKanji() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/japanese/kanji.json');
      final List list = jsonDecode(jsonStr);
      setState(() {
        _kanjiList = list.map((e) => KanjiItem.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showKanjiDetail(KanjiItem item) {
    TtsService().speakJapanese(item.kanji);
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.shade200, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.kanji,
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.grade,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.strokeCount} เส้นขีด',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.meaning,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      iconSize: 28,
                      onPressed: () => TtsService().speakJapanese(item.kanji),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Readings: Onyomi & Kunyomi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('เสียงจีน (Onyomi): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                          Text(item.onyomi.join(', '), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('เสียงญี่ปุ่น (Kunyomi): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                          Text(item.kunyomi.join(', '), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mnemonics / Visual memory trick
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.orange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('เทคนิคการจำภาพ (Mnemonics):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown)),
                            const SizedBox(height: 4),
                            Text(item.mnemonics, style: const TextStyle(fontSize: 13, height: 1.35)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vocabulary usage in real sentences
                const Text('การใช้งานและคำศัพท์ที่พบบ่อย:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ...item.vocabulary.map((v) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(v.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1976D2))),
                        const SizedBox(width: 8),
                        Text('(${v.reading})', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const Spacer(),
                        Text(v.meaning, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        IconButton(
                          icon: const Icon(Icons.volume_up, size: 18),
                          onPressed: () => TtsService().speakJapanese(v.word),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Button to practice writing this kanji
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Adapt Kanji to KanaChar interface for writing canvas
                      final kanaChar = KanaChar(
                        char: item.kanji,
                        romaji: item.onyomi.isNotEmpty ? item.onyomi.first : item.meaning,
                        thai: item.meaning,
                        category: 'kanji',
                        mouthGuide: MouthGuide(
                          shapeName: item.meaning,
                          instruction: item.strokeGuide,
                          thaiApproximation: item.meaning,
                          lipOpening: 'medium',
                          tonguePosition: 'medium',
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WritingPracticeScreen(
                            initialChar: kanaChar,
                            sourceDataset: 'kanji',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: Text('ฝึกเขียนคันจิตัวนี้ (${item.kanji})'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('คันจิพื้นฐาน N5 (Kanji Master)'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFF1A237E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'แตะการ์ดคันจิเพื่อดูเสียงอ่าน (Onyomi/Kunyomi), เทคนิคการจำภาพ และฝึกเขียนตามลำดับเส้น',
                    style: TextStyle(color: Colors.indigo.shade900, fontSize: 13, fontWeight: FontWeight.w500),
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
                childAspectRatio: 0.88,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _kanjiList.length,
              itemBuilder: (context, index) {
                final item = _kanjiList[index];
                return InkWell(
                  onTap: () => _showKanjiDetail(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.shade100, width: 1.5),
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
                          item.kanji,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.meaning,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.strokeCount} ขีด',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
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
