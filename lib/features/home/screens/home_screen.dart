import 'package:flutter/material.dart';
import '../../../core/services/update_service.dart';
import '../../../core/widgets/update_dialog.dart';
import '../../alphabet/screens/alphabet_learning_screen.dart';
import '../../alphabet/screens/writing_practice_screen.dart';
import '../../shadowing/screens/shadowing_screen.dart';
import '../../quiz/screens/quiz_screen.dart';
import '../../ai_tutor/screens/ai_tutor_screen.dart';
import '../../ai_tutor/screens/settings_screen.dart';
import 'progress_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLanguage = 'Japanese'; // 'Japanese' or 'English'
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    // Clean any leftover temporary update files from previous sessions
    _updateService.cleanLeftoverFiles();

    // Auto-check for updates from GitHub on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate(manual: false);
    });
  }

  Future<void> _checkUpdate({bool manual = false}) async {
    final info = await _updateService.checkForUpdate(force: manual);
    if (!mounted) return;

    if (info != null && info.isNewer) {
      UpdateDialog.show(context, info);
    } else if (manual) {
      final currentVer = await _updateService.getCurrentAppVersion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('คุณกำลังใช้งานเวอร์ชันล่าสุดแล้ว ($currentVer)'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('language 0', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'ตรวจสอบการอัปเดต',
            icon: const Icon(Icons.system_update_rounded),
            onPressed: () => _checkUpdate(manual: true),
          ),
          IconButton(
            tooltip: 'ความคืบหน้าการเรียน',
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'ตั้งค่า LLM Server',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          // Language Switcher Dropdown
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                dropdownColor: const Color(0xFFD32F2F),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Japanese', child: Text('🇯🇵 ภาษาญี่ปุ่น')),
                  DropdownMenuItem(value: 'English', child: Text('🇬🇧 ภาษาอังกฤษ')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLanguage = val);
                    if (val == 'English') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เลือกคอร์สภาษาอังกฤษ: โครงสร้างบทเรียน Phonics & Shadowing พร้อมขยายต่อได้ทันที')),
                      );
                    }
                  }
                },
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const UpdateFloatingWidget(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Overall Progress Summary Banner (Clickable)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00796B), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00796B).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.insights, color: Colors.amberAccent, size: 30),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'แดชบอร์ดความคืบหน้าการเรียน',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ดูสถิติตัวอักษรที่คัดแล้ว, บท Shadowing ที่ซ้อม, และคะแนนแบบทดสอบ',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'เส้นทางการเรียนรู้ (Learning Roadmap)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Step 1: Alphabet & Phonics
            _buildLearningCard(
              context: context,
              step: 'ขั้นตอนที่ 1',
              title: 'จำตัวอักษร & แนะนำรูปปาก (Alphabet & Phonics)',
              description: 'สำหรับผู้เริ่มต้นจาก 0: แตะฟังเสียงตัวอักษร ดูภาพรูปปากและเทคนิคขยับลิ้นเทียบเสียงไทย',
              icon: Icons.translate,
              color: const Color(0xFFD32F2F),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlphabetLearningScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // Step 1.5: Stroke Writing Practice
            _buildLearningCard(
              context: context,
              step: 'ฝึกเขียนตัวอักษร',
              title: 'ฝึกคัดลายมือตามลำดับเส้น (Stroke Order Canvas)',
              description: 'กระดานตารางคัดลายมือแบบญี่ปุ่น: ลากเส้นเขียนตามรอยประ นับจำนวนเส้น ลบหรือย้อนกลับได้ และซ่อนเส้นนำเพื่อทดสอบความจำ',
              icon: Icons.draw_outlined,
              color: const Color(0xFFE65100),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WritingPracticeScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // Step 2: Shadowing & Daily Life
            _buildLearningCard(
              context: context,
              step: 'ขั้นตอนที่ 2',
              title: 'Shadowing ฝึกพูดบทสนทนาชีวิตประจำวัน',
              description: 'อิงแหล่งข้อมูลฟรีจาก NHK World & JP-MIRAI: ฟังเจ้าของภาษา อัดเสียงตนเอง แล้วกดเทียบเสียงได้ทันที',
              icon: Icons.record_voice_over,
              color: const Color(0xFF1976D2),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShadowingScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // Step 3: Quizzes & Sentence Builder
            _buildLearningCard(
              context: context,
              step: 'ขั้นตอนที่ 3',
              title: 'ทดสอบความจำ & ระบบต่อประโยค (Quiz & Builder)',
              description: 'ทดสอบจำเสียงคำศัพท์ และฝึกเรียงคำเป็นประโยคที่ถูกต้องตามหลักไวยากรณ์ พร้อมคำอธิบายข้อที่ผิด',
              icon: Icons.quiz_outlined,
              color: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // Step 4: AI Tutor (Gemma 4: 31B)
            _buildLearningCard(
              context: context,
              step: 'ผู้ช่วยส่วนตัว',
              title: 'AI ติวเตอร์ & แนะนำการเรียนเฉพาะบุคคล',
              description: 'เชื่อมต่อ Ollama (Gemma 4: 31B): ตรวจสอบไวยากรณ์ แต่งบทสนทนา และวิเคราะห์ว่าควรเรียนอะไรต่อ',
              icon: Icons.psychology,
              color: const Color(0xFF6A1B9A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiTutorScreen()),
                );
              },
            ),
          ],
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildLearningCard({
    required BuildContext context,
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      step,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
