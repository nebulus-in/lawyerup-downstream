import 'package:flutter/material.dart';
import 'legal/view/legal_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unsettled Legal App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1463E0)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const LegalPage(),
    );
  }
}
