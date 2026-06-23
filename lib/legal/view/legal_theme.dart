import 'package:flutter/material.dart';

class LegalTheme {
  static const ink = Color(0xFF0D1220);
  static const blue = Color(0xFF1463E0);
  static const blueBg = Color(0xFFE8F0FE);
  static const page = Color(0xFFEEF1F5);
  static const muted = Color(0xFF9AA3B2);
  static const field = Color(0xFFF4F6FA);

  static final today = DateTime(2026, 6, 22);
  static const monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const _casePalette = {
    'CIVIL': [Color(0xFF1463E0), Color(0xFFE8F0FE)],
    'CRIMINAL': [Color(0xFFE07A14), Color(0xFFFFF4EC)],
    'FAMILY': [Color(0xFF9B59B6), Color(0xFFF5EEFF)],
    'CORPORATE': [Color(0xFF1A8A4A), Color(0xFFE8F5EE)],
  };

  static const folderPalette = [
    [Color(0xFF1463E0), Color(0xFFE8F0FE)],
    [Color(0xFF1A8A4A), Color(0xFFE8F5EE)],
    [Color(0xFF9B59B6), Color(0xFFF5EEFF)],
    [Color(0xFFE07A14), Color(0xFFFFF4EC)],
    [Color(0xFFC0392B), Color(0xFFFCE8E8)],
  ];

  static const folderTemplates = {
    'CIVIL': ['Pleadings', 'Discovery', 'Evidence', 'Correspondence'],
    'CRIMINAL': ['FIR', 'Bail Documents', 'Evidence', 'Witness Statements'],
    'FAMILY': ['Petition', 'Financial Disclosure', 'Custody & Welfare', 'Correspondence'],
    'CORPORATE': ['Contracts', 'Due Diligence', 'Compliance', 'Resolutions'],
  };

  static List<String> foldersForType(String type) => List<String>.from(
      folderTemplates[type] ?? const ['Pleadings', 'Evidence', 'Correspondence']);

  static Color getCaseColor(String type) {
    return _casePalette[type]?[0] ?? const Color(0xFF718096);
  }

  static Color getCaseBg(String type) {
    return _casePalette[type]?[1] ?? const Color(0xFFF0F2F5);
  }

  static Color getCategoryColor(int index) {
    return folderPalette[index % folderPalette.length][0];
  }

  static Color getCategoryBg(int index) {
    return folderPalette[index % folderPalette.length][1];
  }

  static const sheetDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  );

  static BoxDecoration cardDecoration({
    double radius = 16,
    double blur = 14,
    double opacity = 0.06,
    double dy = 4,
    Color color = Colors.white,
    BoxBorder? border,
  }) {
    return BoxDecoration(
      color: color,
      border: border,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: opacity),
            blurRadius: blur,
            offset: Offset(0, dy)),
      ],
    );
  }

  static String weekdayName(int wd) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[(wd - 1) % 7];
  }
}
