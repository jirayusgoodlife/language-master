import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/progress_service.dart';
import '../models/nhk_lesson.dart';

class ShadowingScreen extends StatefulWidget {
  const ShadowingScreen({super.key});

  @override
  State<ShadowingScreen> createState() => _ShadowingScreenState();
}

class _ShadowingScreenState extends State<ShadowingScreen> {
  List<NhkLesson> _lessons = [];
  bool _isLoading = true;
  NhkLesson? _currentLesson;
  int _activeLineIndex = 0;

  // Recording & Playback comparison
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _userAudioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _recordedFilePath;
  bool _isPlayingUserAudio = false;

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _userAudioPlayer.onPlayerComplete.listen((_) {
      setState(() => _isPlayingUserAudio = false);
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _userAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/japanese/nhk_lessons.json');
      final List list = jsonDecode(jsonStr);
      final lessons = list.map((e) => NhkLesson.fromJson(e)).toList();
      setState(() {
        _lessons = lessons;
        if (lessons.isNotEmpty) _currentLesson = lessons.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/user_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordedFilePath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถบันทึกเสียงได้: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });
      if (mounted) {
        if (_currentLesson != null) {
          ProgressService().markShadowingCompleted(_currentLesson!.id);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกเสียงเรียบร้อย! สามารถกดฟังเพื่อเทียบเสียงได้เลย (บันทึกความคืบหน้าแล้ว)')),
        );
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _playUserRecording() async {
    if (_recordedFilePath != null) {
      setState(() => _isPlayingUserAudio = true);
      await _userAudioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_lessons.isEmpty) {
      return const Scaffold(body: Center(child: Text('ไม่พบบทเรียน')));
    }

    final lesson = _currentLesson ?? _lessons.first;
    final activeLine = lesson.shadowingLines.isNotEmpty
        ? lesson.shadowingLines[_activeLineIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shadowing: บทที่ ${lesson.lessonNumber}'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Lesson selector chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _lessons.map((l) {
                  final isSelected = l.id == lesson.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('บทที่ ${l.lessonNumber}: ${l.title}'),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade100,
                      onSelected: (val) {
                        setState(() {
                          _currentLesson = l;
                          _activeLineIndex = 0;
                          _recordedFilePath = null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Key phrase & cultural tip
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.indigo.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lesson.difficulty,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'สถานการณ์: ${lesson.scenario}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('ประโยคสำคัญประจำบท (Key Phrase):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    lesson.keyPhrase['japanese'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    lesson.keyPhrase['romaji'] ?? '',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 14),
                  ),
                  Text(
                    lesson.keyPhrase['thai'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'เกร็ดวัฒนธรรม: ${lesson.culturalTip}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Shadowing Practice Card
            if (activeLine != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ฝึกพูดตามทีละท่อน (${_activeLineIndex + 1}/${lesson.shadowingLines.length})',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => TtsService().speakJapanese(activeLine.japanese),
                          icon: const Icon(Icons.volume_up_rounded),
                          tooltip: 'ฟังเสียงเจ้าของภาษา (Offline)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      activeLine.japanese,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeLine.romaji,
                      style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeLine.thai,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeLine.tips,
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Side-by-Side Voice Comparison Controls (Offline Mode!)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🎙️ ห้องซ้อมพูด & เทียบเสียง (ทำงานแบบ Offline 100%)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 10,
                            children: [
                              // 1. Play Native Audio
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => TtsService().speakJapanese(activeLine.japanese),
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('1. ฟังต้นแบบ'),
                              ),

                              // 2. Record User Voice
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRecording ? Colors.red : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isRecording ? _stopRecording : _startRecording,
                                icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 18),
                                label: Text(_isRecording ? 'หยุดอัด' : '2. อัดเสียงฉัน'),
                              ),

                              // 3. Play Back User Voice
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _recordedFilePath != null && !_isPlayingUserAudio
                                    ? _playUserRecording
                                    : null,
                                icon: Icon(_isPlayingUserAudio ? Icons.volume_up : Icons.headphones, size: 18),
                                label: const Text('3. เทียบเสียงฉัน'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _activeLineIndex > 0
                              ? () => setState(() => _activeLineIndex--)
                              : null,
                          child: const Text('◀ ประโยคก่อนหน้า'),
                        ),
                        ElevatedButton(
                          onPressed: _activeLineIndex < lesson.shadowingLines.length - 1
                              ? () => setState(() => _activeLineIndex++)
                              : null,
                          child: const Text('ประโยคถัดไป ▶'),
                        ),
                      ],
                    )
                  ],
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
