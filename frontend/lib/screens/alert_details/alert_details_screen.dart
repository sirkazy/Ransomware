import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../models/alert_model.dart';

class AlertDetailsScreen extends StatefulWidget {
  final String alertId;
  const AlertDetailsScreen({super.key, required this.alertId});

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  bool _isActing = false;
  String? _actionResult;
  bool _actionSuccess = false;

  @override
  Widget build(BuildContext context) {
    final alert = context.read<AlertsProvider>().getAlertById(widget.alertId);

    if (alert == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.alertDetails)),
        body: const Center(child: Text('Alert not found')),
      );
    }

    final severityColor = AppColors.severityColor(alert.severity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.alertDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context, alert, severityColor),
          const SizedBox(height: 20),

          _buildInfoCard(
            context,
            AppStrings.detectionReason,
            alert.detectionReason,
            Icons.search_rounded,
            AppColors.primary,
          ),
          const SizedBox(height: 12),

          _buildInfoCard(
            context,
            AppStrings.timeDetected,
            _formatFullTime(alert.timestamp),
            Icons.access_time_rounded,
            AppColors.textSecondary,
          ),
          const SizedBox(height: 12),

          if (alert.affectedFiles.isNotEmpty) ...[
            _buildFilesCard(context, alert.affectedFiles),
            const SizedBox(height: 12),
          ],

          _buildInfoCard(
            context,
            AppStrings.suggestedAction,
            alert.suggestedAction,
            Icons.lightbulb_outline_rounded,
            AppColors.severityWarning,
          ),
          const SizedBox(height: 20),

          // Action result banner
          if (_actionResult != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _actionSuccess
                    ? AppColors.severitySafe.withOpacity(0.08)
                    : AppColors.severityCritical.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _actionSuccess
                      ? AppColors.severitySafe.withOpacity(0.3)
                      : AppColors.severityCritical.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _actionSuccess
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 18,
                    color: _actionSuccess
                        ? AppColors.severitySafe
                        : AppColors.severityCritical,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _actionResult!,
                      style: TextStyle(
                        color: _actionSuccess
                            ? AppColors.severitySafe
                            : AppColors.severityCritical,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          _buildActionButtons(context, alert),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AlertModel alert, Color severityColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: severityColor.withOpacity(0.12),
            ),
            child: Icon(
              alert.severity == 'critical'
                  ? Icons.gpp_bad_rounded
                  : alert.severity == 'warning'
                      ? Icons.warning_rounded
                      : Icons.verified_user_rounded,
              size: 40,
              color: severityColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            alert.title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: severityColor.withOpacity(0.3)),
            ),
            child: Text(
              alert.severity.toUpperCase(),
              style: TextStyle(
                color: severityColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            alert.description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesCard(BuildContext context, List<String> files) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: 18, color: AppColors.severityCritical),
              const SizedBox(width: 8),
              Text(
                AppStrings.affectedFiles,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.severityCritical),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${files.length} files',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AlertModel alert) {
    return Column(
      children: [
        // ── Ignore & Quarantine Row ──────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isActing
                    ? null
                    : () => _executeAction(context, alert.id, 'ignore'),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(AppStrings.ignore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isActing
                    ? null
                    : () => _executeAction(context, alert.id, 'quarantine'),
                icon: const Icon(Icons.shield_rounded, size: 18),
                label: const Text(AppStrings.quarantine),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.severityWarning,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Stop Process (Full width, prominent) ─────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isActing
                ? null
                : () => _confirmStopProcess(context, alert),
            icon: _isActing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.stop_circle_rounded, size: 20),
            label: Text(
              _isActing ? 'Terminating...' : '⛔  Terminate Suspicious Process',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.severityCritical,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmStopProcess(BuildContext context, AlertModel alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.stop_circle_rounded,
                color: AppColors.severityCritical, size: 22),
            SizedBox(width: 10),
            Text(
              'Terminate Process',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'The system will scan for the most suspicious running process '
          '(with the most open file handles in monitored directories) '
          'and forcefully terminate it.\n\nThis is a prevention action — '
          'only proceed if you believe an active attack is in progress.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.severityCritical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _executeAction(context, alert.id, 'stop_process');
            },
            child: const Text('Terminate',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(
      BuildContext context, String alertId, String action) async {
    setState(() {
      _isActing = true;
      _actionResult = null;
    });

    if (alertId.startsWith('LOCAL-')) {
      try {
        final alert = context.read<AlertsProvider>().getAlertById(alertId);
        await Future.delayed(const Duration(milliseconds: 600)); // Simulate mitigation action latency

        String displayMessage = 'Action completed';
        if (action == 'ignore') {
          displayMessage = 'Alert ignored';
        } else if (action == 'quarantine') {
          displayMessage = 'File quarantined successfully (mocked)';
        } else if (action == 'stop_process') {
          displayMessage = '⛔ Terminated: Suspicious simulator process (mocked)';
        }

        if (alert != null) {
          context.read<AlertsProvider>().removeLocalAlert(alertId);

          if (action == 'quarantine' || action == 'stop_process') {
            final monitoring = context.read<MonitoringProvider>();
            for (final path in alert.affectedFiles) {
              monitoring.restoreFileStatus(path);
            }
          }
        }

        setState(() {
          _actionResult = displayMessage;
          _actionSuccess = true;
        });

        if (mounted) {
          context.read<DashboardProvider>().fetchStatus(showLoading: false);
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.severitySafe,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayMessage,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _actionResult = 'Action failed locally.';
          _actionSuccess = false;
        });
      } finally {
        setState(() => _isActing = false);
      }
      return;
    }

    try {
      final api = context.read<DashboardProvider>().apiService;
      final result = await api.performAlertAction(alertId, action);

      final message = result['message'] as String? ?? 'Action completed';
      final processName = result['process_name'] as String?;
      final pid = result['pid'];

      String displayMessage = message;
      if (action == 'stop_process' && processName != null) {
        displayMessage = '⛔ Terminated: $processName (PID $pid)\n$message';
      }

      final isSuccess = result['success'] == true;

      setState(() {
        _actionResult = displayMessage;
        _actionSuccess = isSuccess;
      });

      if (mounted) {
        // Refresh dashboard and alerts after action
        context.read<AlertsProvider>().fetchAlerts(showLoading: false);
        context.read<DashboardProvider>().fetchStatus(showLoading: false);

        if (isSuccess) {
          // Navigate back
          Navigator.of(context).pop();

          // Show confirmation SnackBar on the parent page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.severitySafe,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayMessage,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _actionResult = 'Action failed. Check backend connection.';
        _actionSuccess = false;
      });
    } finally {
      setState(() => _isActing = false);
    }
  }

  String _formatFullTime(DateTime timestamp) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year} at '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}
