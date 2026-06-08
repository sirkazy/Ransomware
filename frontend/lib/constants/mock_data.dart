import '../models/alert_model.dart';
import '../models/monitoring_model.dart';
import '../models/system_status.dart';

class MockData {
  MockData._();

  static SystemStatus get systemStatus => const SystemStatus(
        isSecure: true,
        threatsDetected: 3,
        filesMonitored: 1247,
        suspiciousActivities: 7,
        isMonitoringActive: true,
        threatActivityData: [1, 0, 2, 1, 0, 3, 1, 0, 1, 2, 0, 1],
      );

  static List<AlertModel> get alerts => [
        AlertModel(
          id: 'ALT-001',
          title: 'Ransomware Encryption Detected',
          description:
              'Rapid file encryption pattern detected in Documents folder. Multiple files renamed with .locked extension.',
          severity: 'critical',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
          detectionReason:
              'Mass file rename operations with encryption signatures detected. Over 50 files modified in 30 seconds with entropy increase above 7.8.',
          affectedFiles: [
            '/home/user/Documents/report.docx',
            '/home/user/Documents/budget.xlsx',
            '/home/user/Documents/photos/family.jpg',
            '/home/user/Documents/presentation.pptx',
            '/home/user/Documents/thesis_draft.pdf',
          ],
          suggestedAction:
              'Immediately isolate the affected directory and terminate the suspicious process. Run a full system scan and restore files from backup if available.',
        ),
        AlertModel(
          id: 'ALT-002',
          title: 'Suspicious Registry Modification',
          description:
              'Unauthorized changes to system registry keys associated with startup programs detected.',
          severity: 'critical',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 34)),
          detectionReason:
              'Registry key HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run was modified by an unknown process (PID: 4521). New entry points to an obfuscated executable.',
          affectedFiles: [
            'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run',
            'C:\\Users\\Public\\svchost_update.exe',
          ],
          suggestedAction:
              'Remove the suspicious registry entry and delete the associated executable. Perform a deep scan to identify the source of the modification.',
        ),
        AlertModel(
          id: 'ALT-003',
          title: 'Unusual Network Traffic Pattern',
          description:
              'High-volume outbound traffic to unknown IP addresses detected, possibly exfiltrating data.',
          severity: 'warning',
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
          detectionReason:
              'Process "update_service.exe" initiated 847 outbound connections to IP 185.234.xx.xx on port 443 within 5 minutes. Traffic pattern matches known C2 communication protocols.',
          affectedFiles: [
            'C:\\Windows\\Temp\\update_service.exe',
            'C:\\Users\\user\\AppData\\Local\\cache.dat',
          ],
          suggestedAction:
              'Block the suspicious IP at the firewall level. Terminate the process and quarantine the executable for further analysis.',
        ),
        AlertModel(
          id: 'ALT-004',
          title: 'Shadow Copy Deletion Attempt',
          description:
              'Detected attempt to delete Volume Shadow Copies, a common ransomware preparation technique.',
          severity: 'critical',
          timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 22)),
          detectionReason:
              'Command "vssadmin delete shadows /all /quiet" was intercepted and blocked. This command is commonly used by ransomware to prevent file recovery.',
          affectedFiles: [
            'Volume Shadow Copies',
            'System Restore Points',
          ],
          suggestedAction:
              'The deletion was blocked automatically. Investigate the parent process that initiated this command and check for other signs of compromise.',
        ),
        AlertModel(
          id: 'ALT-005',
          title: 'File Integrity Check Passed',
          description:
              'Scheduled integrity verification of system files completed successfully with no anomalies.',
          severity: 'safe',
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          detectionReason:
              'Routine file integrity monitoring scan completed. All 1,247 monitored files match their known-good hash values.',
          affectedFiles: [],
          suggestedAction:
              'No action required. System files are intact. Next scheduled scan in 6 hours.',
        ),
        AlertModel(
          id: 'ALT-006',
          title: 'Anomalous File Access Pattern',
          description:
              'Unusual sequential file access detected in user directories, possibly a scanning behavior.',
          severity: 'warning',
          timestamp: DateTime.now().subtract(const Duration(hours: 12, minutes: 45)),
          detectionReason:
              'Process "explorer_helper.dll" accessed 234 files sequentially across multiple directories in 2 minutes. This pattern is consistent with file enumeration behavior.',
          affectedFiles: [
            '/home/user/Documents/',
            '/home/user/Desktop/',
            '/home/user/Downloads/',
          ],
          suggestedAction:
              'Monitor the process for further suspicious activity. If file modifications begin, quarantine immediately.',
        ),
        AlertModel(
          id: 'ALT-007',
          title: 'System Scan Completed',
          description:
              'Full system scan completed with no threats found. All monitored files are secure.',
          severity: 'safe',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          detectionReason:
              'Comprehensive behavioral analysis scan completed. No ransomware indicators detected across 3,456 scanned objects.',
          affectedFiles: [],
          suggestedAction:
              'No action needed. Continue regular monitoring schedule.',
        ),
      ];

  static List<MonitoringActivity> get monitoringActivities => [
        MonitoringActivity(
          id: 'MON-001',
          action: 'File Modified',
          filePath: '/home/user/Documents/quarterly_report.docx',
          status: 'normal',
          timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        ),
        MonitoringActivity(
          id: 'MON-002',
          action: 'File Created',
          filePath: '/home/user/Downloads/package_v2.3.tar.gz',
          status: 'normal',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
        MonitoringActivity(
          id: 'MON-003',
          action: 'Bulk Rename Detected',
          filePath: '/home/user/Documents/projects/',
          status: 'suspicious',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
        MonitoringActivity(
          id: 'MON-004',
          action: 'Process Blocked',
          filePath: 'C:\\Windows\\Temp\\svc_update.exe',
          status: 'blocked',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        MonitoringActivity(
          id: 'MON-005',
          action: 'File Read',
          filePath: '/home/user/Documents/notes.txt',
          status: 'normal',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        MonitoringActivity(
          id: 'MON-006',
          action: 'Registry Access',
          filePath: 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion',
          status: 'suspicious',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        MonitoringActivity(
          id: 'MON-007',
          action: 'File Deleted',
          filePath: '/home/user/tmp/cache_old.dat',
          status: 'normal',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        MonitoringActivity(
          id: 'MON-008',
          action: 'Network Connection',
          filePath: '185.234.72.15:443 (outbound)',
          status: 'suspicious',
          timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
        MonitoringActivity(
          id: 'MON-009',
          action: 'File Modified',
          filePath: '/home/user/Documents/budget_2024.xlsx',
          status: 'normal',
          timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
        ),
        MonitoringActivity(
          id: 'MON-010',
          action: 'Encryption Detected',
          filePath: '/home/user/Documents/private/keys.pem',
          status: 'blocked',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        MonitoringActivity(
          id: 'MON-011',
          action: 'File Created',
          filePath: '/home/user/Documents/meeting_notes.md',
          status: 'normal',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        MonitoringActivity(
          id: 'MON-012',
          action: 'Permission Change',
          filePath: '/etc/shadow',
          status: 'blocked',
          timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
        ),
      ];
}
