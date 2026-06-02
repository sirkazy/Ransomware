import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../providers/alerts_provider.dart';
import '../../widgets/alert_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AlertsProvider>();
      provider.fetchAlerts();
      provider.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    if (mounted) {
      context.read<AlertsProvider>().stopAutoRefresh();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AlertsProvider>(
          builder: (context, alertsProvider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    AppStrings.alerts,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: '${AppStrings.allAlerts} (${alertsProvider.allAlerts.length})',
                          value: 'all',
                          selected: alertsProvider.selectedFilter,
                          onTap: () => alertsProvider.setFilter('all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '${AppStrings.critical} (${alertsProvider.criticalCount})',
                          value: 'critical',
                          selected: alertsProvider.selectedFilter,
                          color: AppColors.severityCritical,
                          onTap: () => alertsProvider.setFilter('critical'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '${AppStrings.warning} (${alertsProvider.warningCount})',
                          value: 'warning',
                          selected: alertsProvider.selectedFilter,
                          color: AppColors.severityWarning,
                          onTap: () => alertsProvider.setFilter('warning'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '${AppStrings.safe} (${alertsProvider.safeCount})',
                          value: 'safe',
                          selected: alertsProvider.selectedFilter,
                          color: AppColors.severitySafe,
                          onTap: () => alertsProvider.setFilter('safe'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alert list
                Expanded(
                  child: alertsProvider.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : alertsProvider.alerts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.severitySafe.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text(AppStrings.noAlerts, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: alertsProvider.alerts.length,
                              itemBuilder: (context, index) {
                                final alert = alertsProvider.alerts[index];
                                return AlertCard(
                                  alert: alert,
                                  onTap: () => context.push('/alert/${alert.id}'),
                                );
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.value, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor.withOpacity(0.4) : AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : AppColors.textMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
