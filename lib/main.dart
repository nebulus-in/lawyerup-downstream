import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'legal/view/legal_page.dart';
import 'repositories/legal_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => LegalRepository(),
      child: MaterialApp(
        title: 'Unsettled Legal App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1463E0)),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const LegalPage(),
      ),
    );
  }
}
