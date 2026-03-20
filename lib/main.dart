import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alumni Tracer System',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A152C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A152C),
          primary: const Color(0xFF4A152C),
          secondary: const Color(0xFFC5A046),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(), // ✅ matches your class
    );
  }
}