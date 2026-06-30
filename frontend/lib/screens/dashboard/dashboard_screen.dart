import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/threat_chart.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/simulation_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shieldPulseController;
  late Animation<double> _shieldPulseAnimation;
  DashboardProvider? _dashboardProvider;
  AlertsProvider? _alertsProvider;

  @override
  void initState() {
    super.initState();

    _shieldPulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _shieldPulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _shieldPulseController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchStatus();
      context.read<AlertsProvider>().fetchAlerts();
      context.read<DashboardProvider>().startAutoRefresh();
      context.read<AlertsProvider>().startAutoRefresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    _alertsProvider = Provider.of<AlertsProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _shieldPulseController.dispose();
    _dashboardProvider?.stopAutoRefresh();
    _alertsProvider?.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer2<DashboardProvider, AlertsProvider>(
          builder: (context, dashboard, alerts, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await dashboard.fetchStatus();
                await alerts.fetchAlerts();
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.dashboard,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.appSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showResetDialog(context, dashboard, alerts),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: const Icon(
                            Icons.restart_alt_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildShieldHero(context, dashboard),
                  const SizedBox(height: 20),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      StatisticCard(
                        label: AppStrings.threatsDetected,
                        value: dashboard.threatsDetected,
                        icon: Icons.bug_report_rounded,
                        color: AppColors.severityCritical,
                      ),
                      StatisticCard(
                        label: AppStrings.filesMonitored,
                        value: dashboard.filesMonitored,
                        icon: Icons.folder_open_rounded,
                        color: AppColors.primary,
                      ),
                      StatisticCard(
                        label: AppStrings.suspiciousActivities,
                        value: dashboard.suspiciousActivities,
                        icon: Icons.visibility_rounded,
                        color: AppColors.severityWarning,
                      ),
                      StatisticCard(
                        label: AppStrings.activeMonitoring,
                        value: dashboard.isMonitoringActive ? 1 : 0,
                        icon: Icons.radar_rounded,
                        color: AppColors.severitySafe,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (dashboard.threatActivityData.isNotEmpty)
                    ThreatChart(data: dashboard.threatActivityData),

                  const SizedBox(height: 8),
                  // ── Simulation Panel ─────────────────────────────
                  // const Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 20),
                  //   child: Divider(color: AppColors.surfaceBorder, height: 28),
                  // ),
                  // const SimulationPanel(),
                  // const Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 20),
                  //   child: Divider(color: AppColors.surfaceBorder, height: 28),
                  // ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.recentAlerts,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/alerts'),
                        child: const Text(
                          AppStrings.viewAll,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...alerts.allAlerts.take(3).map(
                        (alert) => AlertCard(
                          alert: alert,
                          onTap: () => context.push('/alert/${alert.id}'),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showResetDialog(
    BuildContext context,
    DashboardProvider dashboard,
    AlertsProvider alerts,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.restart_alt_rounded, color: AppColors.severityWarning, size: 22),
            SizedBox(width: 10),
            Text(
              'Reset System',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'This will clear ALL alerts and monitoring events, returning the system to a clean Secure state.\n\nThis action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.severityWarning,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await dashboard.resetSystem();
                if (context.mounted) {
                  await alerts.fetchAlerts(showLoading: false);
                  await context.read<MonitoringProvider>().fetchActivities(showLoading: false);
                }
              } catch (_) {}
            },
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldHero(BuildContext context, DashboardProvider dashboard) {
    final isSecure = dashboard.isSecure;
    final shieldColor =
        isSecure ? AppColors.shieldSecure : AppColors.shieldThreat;
    final statusText =
        isSecure ? AppStrings.secure : AppStrings.threatDetected;
    final statusIcon =
        isSecure ? Icons.verified_user_rounded : Icons.gpp_bad_rounded;

    return AnimatedBuilder(
      animation: _shieldPulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: shieldColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shieldColor
                    .withOpacity(0.08 * _shieldPulseAnimation.value),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shieldColor.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: shieldColor.withOpacity(
                          0.2 * _shieldPulseAnimation.value),
                      blurRadius: 30 * _shieldPulseAnimation.value,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  size: 56,
                  color: shieldColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.systemStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                statusText,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: shieldColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: shieldColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: shieldColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: shieldColor,
                        boxShadow: [
                          BoxShadow(
                            color: shieldColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dashboard.isMonitoringActive
                          ? 'Protection Active'
                          : 'Protection Inactive',
                      style: TextStyle(
                        color: shieldColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
