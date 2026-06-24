import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../providers/alerts_provider.dart';
import '../services/api_service.dart';

class SimulationPanel extends StatefulWidget {
  const SimulationPanel({super.key});

  @override
  State<SimulationPanel> createState() => _SimulationPanelState();
}

class _SimulationPanelState extends State<SimulationPanel> {
  String? _runningType;
  String? _lastResult;
  bool _hasError = false;

  static const _scenarios = [
    _SimScenario(
      type: 'rapid_modification',
      label: 'Rapid File Modification',
      description: 'Modifies 50 files in rapid succession, simulating ransomware\'s mass encryption read/write cycle.',
      icon: Icons.edit_document,
      color: AppColors.severityWarning,
      badge: 'WARNING',
      rule: 'Rule 1',
    ),
    _SimScenario(
      type: 'bulk_rename',
      label: 'Bulk File Rename',
      description: 'Renames 15 files rapidly to .bak extension, simulating an early-stage file sweep by ransomware.',
      icon: Icons.drive_file_rename_outline_rounded,
      color: AppColors.severityWarning,
      badge: 'WARNING',
      rule: 'Rule 3',
    ),
    _SimScenario(
      type: 'mass_extension',
      label: 'Mass Extension Change',
      description: 'Renames 15 files to .locked / .encrypted / .crypt — the strongest ransomware indicator.',
      icon: Icons.lock_rounded,
      color: AppColors.severityCritical,
      badge: 'CRITICAL',
      rule: 'Rule 2',
    ),
    _SimScenario(
      type: 'all',
      label: 'Full Attack Simulation',
      description: 'Runs all attack stages at once: rapid modifications, bulk renames, and mass extension changes.',
      icon: Icons.warning_amber_rounded,
      color: AppColors.primary,
      badge: 'ALL RULES',
      rule: 'All',
    ),
  ];

  Future<void> _runSimulation(String type, ApiService api) async {
    setState(() {
      _runningType = type;
      _lastResult = null;
      _hasError = false;
    });

    try {
      final result = await api.triggerSimulation(type);
      final created = result['files_created'] ?? 0;
      final modified = result['files_modified'] ?? 0;
      final renamed = result['files_renamed'] ?? 0;

      setState(() {
        _lastResult = 'Done — $created created, $modified modified, $renamed renamed.';
        _hasError = false;
      });

      if (mounted) {
        // Trigger immediate data refresh
        context.read<DashboardProvider>().fetchStatus(showLoading: false);
        context.read<AlertsProvider>().fetchAlerts(showLoading: false);
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Error running simulation.';
        _hasError = true;
      });
    } finally {
      setState(() => _runningType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<DashboardProvider>().apiService;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attack Simulator',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    'Trigger detection scenarios',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Simulation Buttons
        ...(_scenarios.map((s) => _ScenarioTile(
              scenario: s,
              isRunning: _runningType == s.type,
              isDisabled: _runningType != null && _runningType != s.type,
              onTap: () => _runSimulation(s.type, api),
            ))),

        // Result Banner
        if (_lastResult != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _hasError
                  ? AppColors.severityCritical.withOpacity(0.08)
                  : AppColors.severitySafe.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hasError
                    ? AppColors.severityCritical.withOpacity(0.3)
                    : AppColors.severitySafe.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: _hasError ? AppColors.severityCritical : AppColors.severitySafe,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastResult!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasError ? AppColors.severityCritical : AppColors.severitySafe,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final _SimScenario scenario;
  final bool isRunning;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ScenarioTile({
    required this.scenario,
    required this.isRunning,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = scenario.color;
    final opacity = isDisabled ? 0.4 : 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: (isDisabled || isRunning) ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isRunning ? color.withOpacity(0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRunning ? color.withOpacity(0.5) : AppColors.surfaceBorder,
                width: isRunning ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isRunning
                      ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(scenario.icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),

                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            scenario.label,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              scenario.badge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        scenario.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),

                // Arrow / Running indicator
                const SizedBox(width: 8),
                Icon(
                  isRunning ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
                  color: isRunning ? color : AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimScenario {
  final String type;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String badge;
  final String rule;

  const _SimScenario({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.badge,
    required this.rule,
  });
}
