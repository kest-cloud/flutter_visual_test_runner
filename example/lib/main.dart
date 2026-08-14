import 'package:flutter/material.dart';
import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    VisualTestRunner(
      enabled: true,
      specPath: 'assets/test_specs/plain_english_tests.txt',
      initialSpeed: 0.5,
      autoStart: true,
      child: const ExampleEcommerceApp(),
    ),
  );
}

class ExampleEcommerceApp extends StatelessWidget {
  const ExampleEcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visual Test Runner Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
