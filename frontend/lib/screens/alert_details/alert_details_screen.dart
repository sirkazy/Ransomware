import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/alerts_provider.dart';
import '../../models/alert_model.dart';

class AlertDetailsScreen extends StatelessWidget {
  final String alertId;

  const AlertDetailsScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context) {
    final alert = context.read<AlertsProvider>().getAlertById(alertId);

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
          // Threat header
          _buildHeader(context, alert, severityColor),
          const SizedBox(height: 20),

          // Detection reason
          _buildInfoCard(context, AppStrings.detectionReason, alert.detectionReason, Icons.search_rounded, AppColors.primary),
          const SizedBox(height: 12),

          // Time detected
          _buildInfoCard(context, AppStrings.timeDetected, _formatFullTime(alert.timestamp), Icons.access_time_rounded, AppColors.textSecondary),
          const SizedBox(height: 12),

          // Affected files
          if (alert.affectedFiles.isNotEmpty) ...[
            _buildFilesCard(context, alert.affectedFiles),
            const SizedBox(height: 12),
          ],

          // Suggested action
          _buildInfoCard(context, AppStrings.suggestedAction, alert.suggestedAction, Icons.lightbulb_outline_rounded, AppColors.severityWarning),
          const SizedBox(height: 28),

          // Action buttons
          _buildActionButtons(context),
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
              alert.severity == 'critical' ? Icons.gpp_bad_rounded : alert.severity == 'warning' ? Icons.warning_rounded : Icons.verified_user_rounded,
              size: 40, color: severityColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(alert.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
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
              style: TextStyle(color: severityColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          Text(alert.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content, IconData icon, Color color) {
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
              Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5)),
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
              const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.severityCritical),
              const SizedBox(width: 8),
              Text(AppStrings.affectedFiles, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.severityCritical)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
                child: Text('${files.length} files', style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map((file) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(file, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showAction(context, AppStrings.ignore),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text(AppStrings.ignore),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.surfaceBorder)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAction(context, AppStrings.quarantine),
            icon: const Icon(Icons.shield_rounded, size: 18),
            label: const Text(AppStrings.quarantine),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.severityWarning, foregroundColor: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAction(context, AppStrings.stopProcess),
            icon: const Icon(Icons.stop_circle_rounded, size: 18),
            label: const Text('Stop', overflow: TextOverflow.ellipsis),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.severityCritical, foregroundColor: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.severitySafe, size: 20),
            const SizedBox(width: 10),
            Text('$action action executed successfully'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatFullTime(DateTime timestamp) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year} at '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}
