import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/monitoring_provider.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      Row(
                        children: [
                          _SummaryChip(label: 'Normal', count: monitoring.normalCount, color: AppColors.severitySafe),
                          const SizedBox(width: 8),
                          _SummaryChip(label: 'Suspicious', count: monitoring.suspiciousCount, color: AppColors.severityWarning),
                          const SizedBox(width: 8),
                          _SummaryChip(label: 'Blocked', count: monitoring.blockedCount, color: AppColors.severityCritical),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: monitoring.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: monitoring.activities.length,
                          itemBuilder: (context, index) {
                            return MonitoringTile(activity: monitoring.activities[index]);
                          },
                        ),
                ),
              ],
            );
          },
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
