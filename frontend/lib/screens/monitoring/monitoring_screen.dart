import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../widgets/monitoring_tile.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  MonitoringProvider? _monitoringProvider;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MonitoringProvider>();
      provider.fetchActivities();
      provider.startSimulation();
      provider.startAutoRefresh();
      provider.startLocalMonitoring();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _monitoringProvider = Provider.of<MonitoringProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _monitoringProvider?.stopAutoRefresh();
    _monitoringProvider?.stopSimulation();
    _monitoringProvider?.stopLocalMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer<MonitoringProvider>(
            builder: (context, monitoring, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.monitoring,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            _buildLiveIndicator(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Activity Feed'),
                              Tab(text: 'Device Files'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildActivityFeed(monitoring),
                        _buildDeviceFilesTab(context, monitoring),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(MonitoringProvider monitoring) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
          child: Row(
            children: [
              _SummaryChip(label: 'Normal', count: monitoring.normalCount, color: AppColors.severitySafe),
              const SizedBox(width: 8),
              _SummaryChip(label: 'Suspicious', count: monitoring.suspiciousCount, color: AppColors.severityWarning),
              const SizedBox(width: 8),
              _SummaryChip(label: 'Blocked', count: monitoring.blockedCount, color: AppColors.severityCritical),
            ],
          ),
        ),
        Expanded(
          child: monitoring.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  itemCount: monitoring.activities.length,
                  itemBuilder: (context, index) {
                    return MonitoringTile(activity: monitoring.activities[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceFilesTab(BuildContext context, MonitoringProvider monitoring) {
    final alertsProvider = context.read<AlertsProvider>();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Device File Monitoring',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monitor local phone files in real-time. Files are checked locally and are never uploaded.',
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => monitoring.pickAndAddLocalFiles(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.file_open_rounded, size: 18),
                label: const Text(
                  'Select Files from Device',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: monitoring.localFiles.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: monitoring.localFiles.length,
                  itemBuilder: (context, index) {
                    final file = monitoring.localFiles[index];
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getFileStatusColor(file.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getFileIcon(file.name, file.status),
                              color: _getFileStatusColor(file.status),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  file.path,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatBytes(file.size),
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildStatusBadge(file.status),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (file.status != 'encrypted' && file.status != 'deleted') ...[
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.enhanced_encryption_rounded,
                                        color: AppColors.severityWarning,
                                        size: 20,
                                      ),
                                      tooltip: 'Simulate Encryption Attack',
                                      onPressed: () => monitoring.simulateAttackOnFile(
                                        file.path,
                                        alertsProvider,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.severityCritical,
                                      size: 20,
                                    ),
                                    tooltip: 'Stop Monitoring',
                                    onPressed: () => monitoring.removeLocalFile(file.path),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Icon(
                Icons.folder_zip_outlined,
                size: 60,
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No local files monitored',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select important files from your phone storage using the panel above. Any changes made to them outside the app will be captured here in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFileStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'secure':
        return AppColors.severitySafe;
      case 'modified':
        return AppColors.severityWarning;
      case 'deleted':
      case 'encrypted':
        return AppColors.severityCritical;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getFileIcon(String filename, String status) {
    if (status == 'encrypted') return Icons.lock_rounded;
    if (status == 'deleted') return Icons.delete_forever_rounded;
    
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildStatusBadge(String status) {
    final color = _getFileStatusColor(status);
    String label = status.toUpperCase();
    if (status == 'encrypted') label = 'ENCRYPTED (SIM)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.severitySafe.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.severitySafe.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.severitySafe.withOpacity(_blinkController.value),
                  boxShadow: [BoxShadow(color: AppColors.severitySafe.withOpacity(0.5 * _blinkController.value), blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 6),
              const Text('LIVE', style: TextStyle(color: AppColors.severitySafe, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(count.toString(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

