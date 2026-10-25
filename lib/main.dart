import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/isolate_demo/presentation/screens/isolate_demo_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IsolateDemoApp());
}

/// Ứng dụng Demo Chủ đề 03:
/// Xử lý tác vụ nặng với Isolate (`compute`) để giữ mượt giao diện.
class IsolateDemoApp extends StatelessWidget {
  const IsolateDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chủ đề 03 - Isolate & compute Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const IsolateDemoScreen(),
    );
  }
}
