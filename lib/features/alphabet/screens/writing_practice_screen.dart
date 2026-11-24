import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/progress_service.dart';
import '../models/kana_char.dart';
import '../widgets/stroke_canvas_painter.dart';
import '../widgets/dashed_line_painter.dart';
import '../widgets/immediate_pan_gesture_recognizer.dart';
import '../services/stroke_evaluator.dart';

class WritingPracticeScreen extends StatefulWidget {
  final KanaChar? initialChar;
  final String sourceDataset; // 'hiragana', 'katakana', 'kanji'

  const WritingPracticeScreen({
    super.key,
    this.initialChar,
    this.sourceDataset = 'hiragana',
  });

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  List<KanaChar> _characters = [];
  late String _currentDataset;
  bool _isLoading = true;
  int _currentIndex = 0;

  // Drawing state
  final List<StrokeLine> _userStrokes = [];
  StrokeLine? _activeStroke;
  bool _showGuide = true;
  bool _showGrid = true;
  double _guideOpacity = 0.28; // Subtle faint opacity (28%)
  int? _matchScore; // Evaluation accuracy percentage (0-100%)

  @override
  void initState() {
    super.initState();
    _currentDataset = widget.sourceDataset;
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
    try {
      String path = 'assets/data/japanese/hiragana.json';
      if (_currentDataset == 'katakana') {
        path = 'assets/data/japanese/katakana.json';
      } else if (_currentDataset == 'kanji') {
        path = 'assets/data/japanese/kanji.json';
      }

      final jsonStr = await rootBundle.loadString(path);
      final List list = jsonDecode(jsonStr);

      List<KanaChar> chars;
      if (_currentDataset == 'kanji') {
        chars = list.map((e) {
          final k = e as Map<String, dynamic>;
          final onyomi = (k['onyomi'] as List? ?? []).join(', ');
          final meaning = k['meaning'] ?? '';
          return KanaChar(
            char: k['kanji'] ?? '',
            romaji: onyomi.isNotEmpty ? onyomi : meaning,
            thai: meaning,
            category: 'kanji',
            mouthGuide: MouthGuide(
              shapeName: meaning,
              instruction: k['strokeGuide'] ?? '',
              thaiApproximation: k['mnemonics'] ?? '',
              lipOpening: 'medium',
              tonguePosition: 'medium',
            ),
          );
        }).toList();
      } else {
        chars = list.map((e) => KanaChar.fromJson(e)).toList();
      }

      setState(() {
        _characters = chars;
        if (widget.initialChar != null) {
          final found = chars.indexWhere((c) => c.char == widget.initialChar!.char);
          if (found != -1) _currentIndex = found;
        } else {
          _currentIndex = 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _switchDataset(String dataset) {
    if (_currentDataset == dataset) return;
    setState(() {
      _currentDataset = dataset;
      _currentIndex = 0;
      _clearCanvas();
    });
    _loadCharacters();
  }

  void _clearCanvas() {
    setState(() {
      _userStrokes.clear();
      _activeStroke = null;
      _matchScore = null;
    });
  }

  void _undoStroke() {
    if (_userStrokes.isNotEmpty) {
      setState(() {
        _userStrokes.removeLast();
        _matchScore = null;
      });
    }
  }

  void _nextChar() {
    if (_characters.isEmpty) return;
    setState(() {
      // Endless loop! If at the end, roll over to 0
      _currentIndex = (_currentIndex + 1) % _characters.length;
      _clearCanvas();
    });
    _speakCurrent();
  }

  void _prevChar() {
    if (_characters.isEmpty) return;
    setState(() {
      // Endless loop backwards!
      _currentIndex = (_currentIndex - 1 + _characters.length) % _characters.length;
      _clearCanvas();
    });
    _speakCurrent();
  }

  void _evaluateWriting(double canvasSize) {
    if (_userStrokes.isEmpty || _characters.isEmpty) return;
    final charItem = _characters[_currentIndex];
    final score = StrokeEvaluator.evaluateStrokes(
      userStrokes: _userStrokes,
      targetChar: charItem.char,
      canvasSize: canvasSize,
    );
    setState(() {
      _matchScore = score;
    });
  }

  void _speakCurrent() {
    if (_characters.isNotEmpty) {
      TtsService().speakJapanese(_characters[_currentIndex].char);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_characters.isEmpty) {
      return const Scaffold(body: Center(child: Text('ไม่พบข้อมูลตัวอักษร')));
    }

    final charItem = _characters[_currentIndex];
    final screenSize = MediaQuery.of(context).size;
    final canvasSize = (screenSize.width - 48).clamp(240.0, 360.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('ฝึกเขียน: ${charItem.char} (${charItem.romaji})'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _showGrid ? 'ซ่อนเส้นประกากบาท' : 'แสดงเส้นประกากบาท',
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          IconButton(
            tooltip: _showGuide ? 'ซ่อนเส้นนำ' : 'เปิดเส้นนำ',
            icon: Icon(_showGuide ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showGuide = !_showGuide),
          ),
          IconButton(
            tooltip: 'ฟังเสียงอ่าน',
            icon: const Icon(Icons.volume_up),
            onPressed: _speakCurrent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Dataset Switcher Tabs (Hiragana / Katakana / Kanji)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('ฮิรางานะ (Hiragana)'),
                    selected: _currentDataset == 'hiragana',
                    selectedColor: Colors.orange.shade100,
                    onSelected: (val) {
                      if (val) _switchDataset('hiragana');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('คาตากานะ (Katakana)'),
                    selected: _currentDataset == 'katakana',
                    selectedColor: Colors.orange.shade100,
                    onSelected: (val) {
                      if (val) _switchDataset('katakana');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('คันจิ N5 (Kanji)'),
                    selected: _currentDataset == 'kanji',
                    selectedColor: Colors.orange.shade100,
                    onSelected: (val) {
                      if (val) _switchDataset('kanji');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Header Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      charItem.char,
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Romaji: ${charItem.romaji}  |  เสียงไทย: ${charItem.thai}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'จำนวนเส้นที่ลากแล้ว: ${_userStrokes.length} เส้น',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _speakCurrent,
                    icon: const Icon(Icons.volume_up, size: 22),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Writing Canvas with traditional grid & NHK Stroke Order Guide
            Center(
              child: Container(
                width: canvasSize,
                height: canvasSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Dashed Cross Grid (เส้นประเครื่องหมายบวกตรงกลาง)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DashedLinePainter(showGrid: _showGrid),
                        ),
                      ),

                      // 2. NHK Stroke Order Image Guide (จางๆ แบบปรับความโปร่งแสงได้)
                      if (_showGuide && charItem.strokeImage != null)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Opacity(
                              opacity: _guideOpacity,
                              child: Image.asset(
                                charItem.strokeImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      else if (_showGuide)
                        Positioned.fill(
                          child: Opacity(
                            opacity: _guideOpacity,
                            child: CustomPaint(
                              painter: StrokeCanvasPainter(
                                userStrokes: const [],
                                currentStroke: null,
                                guideChar: charItem.char,
                                showGuide: true,
                                isOverlay: false,
                              ),
                            ),
                          ),
                        ),

                      // 3. Interactive Drawing Surface (User writes right over the guide)
                      // Wrap in Listener to consume pointer events and prevent scrollview interception
                      Positioned.fill(
                        child: Listener(
                          onPointerDown: (_) {
                            // Intercept gesture immediately to block scrollview
                          },
                          behavior: HitTestBehavior.opaque,
                          child: RawGestureDetector(
                            gestures: {
                              ImmediatePanGestureRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                      ImmediatePanGestureRecognizer>(
                                () => ImmediatePanGestureRecognizer(),
                                (ImmediatePanGestureRecognizer instance) {
                                  instance.onStart = (details) {
                                    setState(() {
                                      _activeStroke = StrokeLine(
                                          points: [details.localPosition]);
                                      _matchScore = null;
                                    });
                                  };
                                  instance.onUpdate = (details) {
                                    if (_activeStroke != null) {
                                      setState(() {
                                        _activeStroke!.points
                                            .add(details.localPosition);
                                      });
                                    }
                                  };
                                  instance.onEnd = (details) {
                                    if (_activeStroke != null) {
                                      setState(() {
                                        _userStrokes.add(_activeStroke!);
                                        _activeStroke = null;
                                      });
                                      ProgressService()
                                          .markKanaLearned(charItem.char);
                                    }
                                  };
                                },
                              ),
                            },
                            child: CustomPaint(
                              painter: StrokeCanvasPainter(
                                userStrokes: _userStrokes,
                                currentStroke: _activeStroke,
                                guideChar: charItem.char,
                                showGuide: false,
                                isOverlay: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Canvas Toolbar
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _userStrokes.isNotEmpty ? _undoStroke : null,
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('ย้อนกลับ'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                    elevation: 0,
                  ),
                  onPressed: (_userStrokes.isNotEmpty || _activeStroke != null) ? _clearCanvas : null,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('ล้างกระดาน'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    elevation: 1,
                  ),
                  onPressed: _userStrokes.isNotEmpty ? () => _evaluateWriting(canvasSize) : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('ตรวจลายมือ'),
                ),
                FilterChip(
                  avatar: Icon(_showGuide ? Icons.visibility : Icons.visibility_off, size: 16),
                  label: Text(_showGuide ? 'ซ่อนเส้นนำ' : 'เปิดเส้นนำ'),
                  selected: _showGuide,
                  onSelected: (val) => setState(() => _showGuide = val),
                ),
                FilterChip(
                  avatar: Icon(_showGrid ? Icons.grid_on : Icons.grid_off, size: 16),
                  label: Text(_showGrid ? 'ซ่อนเส้นประ (+)' : 'เปิดเส้นประ (+)'),
                  selected: _showGrid,
                  onSelected: (val) => setState(() => _showGrid = val),
                ),
              ],
            ),
            if (_showGuide) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ความจางของเส้นนำ: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(
                    width: 140,
                    height: 24,
                    child: Slider(
                      value: _guideOpacity,
                      min: 0.1,
                      max: 0.8,
                      divisions: 7,
                      label: '${(_guideOpacity * 100).toInt()}%',
                      onChanged: (val) => setState(() => _guideOpacity = val),
                    ),
                  ),
                  Text('${(_guideOpacity * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ],

            // Match Score Display (ตรวจความถูกต้องเทียบเส้นนำ)
            if (_matchScore != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _matchScore! >= 75
                      ? Colors.green.shade50
                      : (_matchScore! >= 50 ? Colors.amber.shade50 : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _matchScore! >= 75
                        ? Colors.green.shade300
                        : (_matchScore! >= 50 ? Colors.amber.shade300 : Colors.red.shade300),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _matchScore! >= 75
                          ? Icons.verified
                          : (_matchScore! >= 50 ? Icons.thumb_up_alt_outlined : Icons.info_outline),
                      color: _matchScore! >= 75
                          ? Colors.green.shade700
                          : (_matchScore! >= 50 ? Colors.amber.shade800 : Colors.red.shade700),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ความเหมือนเส้นต้นแบบ: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                '$_matchScore%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _matchScore! >= 75
                                      ? Colors.green.shade700
                                      : (_matchScore! >= 50 ? Colors.amber.shade900 : Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _matchScore! >= 80
                                ? '🎉 ยอดเยี่ยมมาก! สัดส่วนและตำแหน่งกึ่งกลางสมบูรณ์'
                                : (_matchScore! >= 60
                                    ? '👍 สวยงามดีแล้ว พยายามรักษาระยะและกึ่งกลางอีกนิด'
                                    : '✍️ ลองพยายามลากเส้นให้อยู่ในกรอบสัดส่วนกึ่งกลางดูอีกครั้งนะครับ'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Navigation Controls (Previous / Next Character)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentIndex > 0 ? _prevChar : null,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ตัวก่อนหน้า'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${_currentIndex + 1} / ${_characters.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _currentIndex < _characters.length - 1 ? _nextChar : null,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ตัวถัดไป'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Example Word Box
            if (charItem.exampleWord != null)
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
                            TextSpan(text: '${charItem.exampleWord!.word} (${charItem.exampleWord!.reading}) = ${charItem.exampleWord!.meaning}'),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, size: 18),
                      onPressed: () => TtsService().speakJapanese(charItem.exampleWord!.reading),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
