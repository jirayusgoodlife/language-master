import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  static Future<void> show(BuildContext context, AppUpdateInfo info) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpdateDialog(info: info),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final updateService = UpdateService();

    return AnimatedBuilder(
      animation: updateService,
      builder: (context, _) {
        final status = updateService.status;
        final isDownloading = status == UpdateStatus.downloading;
        final isReady = status == UpdateStatus.readyToInstall;
        final progress = updateService.downloadProgress;
        final percent = (progress * 100).toInt();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isReady
                      ? Colors.green.shade50
                      : const Color(0xFFD32F2F).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReady ? Icons.check_circle_rounded : Icons.system_update_rounded,
                  color: isReady ? Colors.green : const Color(0xFFD32F2F),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady ? 'พร้อมติดตั้งอัปเดต' : 'มีอัปเดตใหม่!',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'เวอร์ชัน ${info.tagName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (!isDownloading && !isReady) ...[
                const Text(
                  'มีเวอร์ชันใหม่ของ language 0 พร้อมให้อัปเดตแล้ว',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes.trim().isNotEmpty
                          ? info.releaseNotes
                          : 'ปรับปรุงประสิทธิภาพและความเสถียรของแอปพลิเคชัน',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ),
                if (info.assetSize != null && info.assetSize! > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ขนาดไฟล์: ${_formatBytes(info.assetSize!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
              if (isDownloading) ...[
                const Text(
                  'กำลังดาวน์โหลดอัปเดตในพื้นหลัง...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    Text(
                      '${_formatBytes(updateService.receivedBytes)} / ${_formatBytes(updateService.totalBytes)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
              if (isReady) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.download_done_rounded, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ดาวน์โหลดเสร็จสมบูรณ์',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'แตะ "ติดตั้งเลย" เพื่อเริ่มการติดตั้ง',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (updateService.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  updateService.errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ],
          ),
          actions: [
            if (!isDownloading && !isReady) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ไว้คราวหน้า', style: TextStyle(color: Colors.grey)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.downloading, size: 18),
                label: const Text('ดาวน์โหลดพื้นหลัง'),
                onPressed: () {
                  updateService.startDownload(runInBackground: true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('กำลังดาวน์โหลด ${info.tagName} ในพื้นหลัง...'),
                      backgroundColor: const Color(0xFFD32F2F),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                label: const Text('ดาวน์โหลดทันที'),
                onPressed: () {
                  updateService.startDownload(runInBackground: false);
                },
              ),
            ],
            if (isDownloading) ...[
              TextButton(
                onPressed: () {
                  updateService.cancelDownload();
                },
                child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('ซ่อนไปทำอย่างอื่น'),
              ),
            ],
            if (isReady) ...[
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                label: const Text('ล้างไฟล์', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  await updateService.cleanDownloadedFiles();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                icon: const Icon(Icons.install_mobile_rounded, size: 18),
                label: const Text('ติดตั้งเลย'),
                onPressed: () {
                  updateService.installUpdate();
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Floating Banner for background download and ready-to-install status
class UpdateFloatingWidget extends StatelessWidget {
  const UpdateFloatingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final updateService = UpdateService();

    return AnimatedBuilder(
      animation: updateService,
      builder: (context, _) {
        final status = updateService.status;
        final isDownloading = status == UpdateStatus.downloading;
        final isReady = status == UpdateStatus.readyToInstall;

        if (!isDownloading && !isReady) {
          return const SizedBox.shrink();
        }

        final progress = updateService.downloadProgress;
        final percent = (progress * 100).toInt();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isReady ? Colors.green.shade700 : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (isDownloading)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDownloading
                          ? 'กำลังดาวน์โหลดอัปเดต ($percent%)'
                          : 'อัปเดตพร้อมติดตั้งแล้ว!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      isDownloading
                          ? 'สามารถใช้งานแอปต่อไปได้ในระหว่างนี้'
                          : 'แตะเพื่อเริ่มติดตั้ง หรือลบไฟล์เมื่อเสร็จสิ้น',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isReady) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => updateService.installUpdate(),
                  child: const Text('ติดตั้ง', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'ลบไฟล์ดาวน์โหลดเพื่อคืนพื้นที่',
                  icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                  onPressed: () => updateService.cleanDownloadedFiles(),
                ),
              ] else ...[
                IconButton(
                  tooltip: 'ดูรายละเอียด',
                  icon: const Icon(Icons.open_in_full_rounded, color: Colors.white70, size: 20),
                  onPressed: () {
                    if (updateService.updateInfo != null) {
                      UpdateDialog.show(context, updateService.updateInfo!);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
