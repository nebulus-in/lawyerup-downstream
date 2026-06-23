import 'package:flutter/material.dart';
import '../legal_theme.dart';

class ResearchView extends StatelessWidget {
  const ResearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('research'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.menu_book_rounded,
                color: LegalTheme.muted, size: 30),
          ),
          const SizedBox(height: 16),
          const Text('Research',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: LegalTheme.ink)),
          const SizedBox(height: 4),
          const Text('Coming soon',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: LegalTheme.muted)),
        ],
      ),
    );
  }
}
