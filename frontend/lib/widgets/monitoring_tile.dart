import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/monitoring_model.dart';

class MonitoringTile extends StatelessWidget {
  final MonitoringActivity activity;

  const MonitoringTile({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.severityColor(activity.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _actionColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _actionIcon,
              color: _actionColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.filePath,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status chip & time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Text(
                  activity.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(activity.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _actionIcon {
    switch (activity.action.toLowerCase()) {
      case 'file modified':
        return Icons.edit_document;
      case 'file created':
        return Icons.note_add_rounded;
      case 'file deleted':
        return Icons.delete_outline_rounded;
      case 'file read':
      case 'file scanned':
        return Icons.find_in_page_rounded;
      case 'bulk rename detected':
        return Icons.drive_file_rename_outline_rounded;
      case 'process blocked':
        return Icons.block_rounded;
      case 'registry access':
        return Icons.settings_applications_rounded;
      case 'network connection':
      case 'outbound connection':
        return Icons.wifi_tethering_rounded;
      case 'encryption detected':
        return Icons.enhanced_encryption_rounded;
      case 'permission change':
        return Icons.admin_panel_settings_rounded;
      case 'hash verified':
        return Icons.verified_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get _actionColor {
    switch (activity.status.toLowerCase()) {
      case 'suspicious':
        return AppColors.severityWarning;
      case 'blocked':
        return AppColors.severityCritical;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
