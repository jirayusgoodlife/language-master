import 'package:flutter/material.dart';
import '../../../core/services/progress_service.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = true;

  Set<String> _learnedKana = {};
  Set<String> _completedShadowing = {};
  int _quizBestScore = 0;

  final int _totalKana = 46;
  final int _totalShadowing = 3;
  final int _totalQuizzes = 4;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final kana = await _progressService.getCompletedKana();
    final shadowing = await _progressService.getCompletedShadowing();
    final quiz = await _progressService.getQuizPassedCount();

    if (mounted) {
      setState(() {
        _learnedKana = kana;
        _completedShadowing = shadowing;
        _quizBestScore = quiz;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final kanaPercent = (_learnedKana.length / _totalKana).clamp(0.0, 1.0);
    final shadowingPercent = (_completedShadowing.length / _totalShadowing).clamp(0.0, 1.0);
    final quizPercent = (_quizBestScore / _totalQuizzes).clamp(0.0, 1.0);
    final overallScore = ((kanaPercent + shadowingPercent + quizPercent) / 3 * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ความคืบหน้าการเรียน (Learning Progress)'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Mastery Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF004D40)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00796B).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: overallScore / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                        ),
                      ),
                      Text(
                        '$overallScore%',
                        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ระดับความเชี่ยวชาญรวม',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ผู้เรียนระดับต้น (Beginner)',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ฝึกฝนต่อเนื่องเพื่อปลดล็อก N5 Master',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'สรุปสถิติรายหมวดหมู่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Category 1: Kana Learning & Writing
            _buildProgressCard(
              title: 'ตัวอักษรและการฝึกเขียน (Hiragana)',
              progressText: '${_learnedKana.length} / $_totalKana ตัวอักษร',
              percent: kanaPercent,
              color: const Color(0xFFD32F2F),
              icon: Icons.draw,
              details: _learnedKana.isEmpty
                  ? 'ยังไม่ได้เริ่มฝึก แตะตัวอักษรหรือฝึกเขียนเพื่อบันทึกสถิติ'
                  : 'ตัวอักษรที่ผ่านแล้ว: ${_learnedKana.take(10).join(', ')}${_learnedKana.length > 10 ? ' ...' : ''}',
            ),

            const SizedBox(height: 14),

            // Category 2: Shadowing
            _buildProgressCard(
              title: 'บทสนทนา Shadowing & เทียบเสียง',
              progressText: '${_completedShadowing.length} / $_totalShadowing บทเรียน',
              percent: shadowingPercent,
              color: const Color(0xFF1976D2),
              icon: Icons.record_voice_over,
              details: 'ซ้อมพูดตามและบันทึกเทียบเสียงสำเนียงญี่ปุ่น',
            ),

            const SizedBox(height: 14),

            // Category 3: Quizzes & Builder
            _buildProgressCard(
              title: 'แบบทดสอบและเรียงประโยค',
              progressText: '$_quizBestScore / $_totalQuizzes คะแนนสูงสุด',
              percent: quizPercent,
              color: const Color(0xFF2E7D32),
              icon: Icons.quiz,
              details: 'การทดสอบคลังคำศัพท์และโครงสร้างไวยากรณ์',
            ),

            const SizedBox(height: 24),

            // Reset Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('รีเซ็ตความคืบหน้า?'),
                    content: const Text('คุณต้องการล้างสถิติการเรียนทั้งหมดเพื่อเริ่มต้นใหม่หรือไม่?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('รีเซ็ตเลย', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _progressService.resetProgress();
                  _loadProgress();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('รีเซ็ตข้อมูลความคืบหน้าการเรียน'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String progressText,
    required double percent,
    required Color color,
    required IconData icon,
    required String details,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                progressText,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
