import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/api_service.dart';
import 'providers/dashboard_provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/alerts_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF141929),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MonitoringProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertsProvider(apiService),
        ),
      ],
      child: const RansomwareGuardianApp(),
    ),
  );
}

class RansomwareGuardianApp extends StatelessWidget {
  const RansomwareGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ransomware Guardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
