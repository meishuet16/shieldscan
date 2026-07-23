import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/scan_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ScanProvider(),
      child: const ShieldScanApp(),
    ),
  );
}

class ShieldScanApp extends StatelessWidget {
  const ShieldScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShieldScan AI - Malaysia Fraud Intelligence Hub',
      debugShowCheckedModeBanner: false,
      theme: buildShieldScanTheme(),
      home: const HomeScreen(),
    );
  }
}
