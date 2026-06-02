import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import 'package:provider/provider.dart';
import '../providers/alerts_provider.dart';

class BottomNavShell extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final ValueChanged<int> onTap;

  const BottomNavShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield_rounded),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.radar_outlined),
              activeIcon: Icon(Icons.radar_rounded),
              label: 'Monitoring',
            ),
            BottomNavigationBarItem(
              icon: Consumer<AlertsProvider>(
                builder: (context, alertsProvider, _) {
                  final count = alertsProvider.criticalCount;
                  if (count > 0) {
                    return Badge(
                      label: Text(count.toString()),
                      backgroundColor: AppColors.severityCritical,
                      child: const Icon(Icons.warning_amber_rounded),
                    );
                  }
                  return const Icon(Icons.warning_amber_rounded);
                },
              ),
              activeIcon: Consumer<AlertsProvider>(
                builder: (context, alertsProvider, _) {
                  final count = alertsProvider.criticalCount;
                  if (count > 0) {
                    return Badge(
                      label: Text(count.toString()),
                      backgroundColor: AppColors.severityCritical,
                      child: const Icon(Icons.warning_rounded),
                    );
                  }
                  return const Icon(Icons.warning_rounded);
                },
              ),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}
