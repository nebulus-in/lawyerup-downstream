import 'package:equatable/equatable.dart';

class CaseFile extends Equatable {
  final int id;
  final String name;
  final String size;
  final String date;

  /// Absolute path to a locally stored file (e.g. a scanned PDF), or null for
  /// records that don't point at a file on disk.
  final String? path;

  const CaseFile({
    required this.id,
    required this.name,
    required this.size,
    required this.date,
    this.path,
  });

  /// Whether this record points at a file that can be opened on the device.
  bool get isLocal => path != null;

  @override
  List<Object?> get props => [id, name, size, date, path];

  CaseFile copyWith({
    String? name,
    String? size,
    String? date,
    String? path,
  }) {
    return CaseFile(
      id: id,
      name: name ?? this.name,
      size: size ?? this.size,
      date: date ?? this.date,
      path: path ?? this.path,
    );
  }
}

class Category extends Equatable {
  final int id;
  final String name;
  final int docs;

  final List<CaseFile> files;

  const Category({
    required this.id,
    required this.name,
    required this.docs,

    this.files = const [],
  });

  @override
  List<Object?> get props => [id, name, docs, files];

  Category copyWith({String? name, List<CaseFile>? files, int? docs}) {
    return Category(
      id: id,
      name: name ?? this.name,
      docs: docs ?? this.docs,

      files: files ?? this.files,
    );
  }

  /// Returns a copy with [file] appended and the doc count incremented.
  Category addFile(CaseFile file) =>
      copyWith(docs: docs + 1, files: [...files, file]);
}

class Case extends Equatable {
  final int id;
  final String name;
  final String number;
  final String court;
  final String type;

  final int docs;
  final String hearing;
  final List<CaseFile> uncategorizedFiles;
  final List<Category> categories;

  const Case({
    required this.id,
    required this.name,
    required this.number,
    required this.court,
    required this.type,

    required this.docs,
    required this.hearing,
    this.uncategorizedFiles = const [],
    this.categories = const [],
  });

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Whether this case has a scheduled hearing (vs. the `'-'` placeholder).
  bool get isScheduled => hearing != '-' && hearing.isNotEmpty;

  /// The `hearing` display string parsed to a date, or null if unscheduled.
  DateTime? get hearingDate => parseHearing(hearing);

  static DateTime? parseHearing(String h) {
    final parts = h.split(' ');
    if (parts.length != 2) return null;
    final m = _monthAbbr.indexOf(parts[0]);
    final d = int.tryParse(parts[1]);
    if (m < 0 || d == null) return null;
    return DateTime(2026, m + 1, d);
  }

  static String formatHearing(DateTime dt) => '${_monthAbbr[dt.month - 1]} ${dt.day}';

  /// Cases with a hearing scheduled for today or later, ordered by date then
  /// name, limited to those falling on the next [maxDays] distinct hearing days.
  ///
  /// Domain logic for "upcoming hearings" lives here rather than in a BLoC so
  /// the orchestration layer stays thin.
  static List<Case> upcomingHearings(List<Case> cases, {int maxDays = 2}) {
    final today = DateTime.now();
    final upcoming = <(Case, DateTime)>[];

    for (final c in cases) {
      final date = c.hearingDate;
      if (date == null || date.isBefore(today)) continue;
      upcoming.add((c, date));
    }

    upcoming.sort((a, b) {
      final byDate = a.$2.compareTo(b.$2);
      return byDate != 0 ? byDate : a.$1.name.compareTo(b.$1.name);
    });

    final days = <DateTime>{};
    final result = <Case>[];
    for (final entry in upcoming) {
      if (!days.contains(entry.$2)) {
        if (days.length == maxDays) break;
        days.add(entry.$2);
      }
      result.add(entry.$1);
    }
    return result;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        number,
        court,
        type,

        docs,
        hearing,
        uncategorizedFiles,
        categories,
      ];

  Case copyWith({
    String? name,
    String? number,
    String? court,
    String? type,

    String? hearing,
    List<Category>? categories,
    List<CaseFile>? uncategorizedFiles,
    int? docs,
  }) {
    return Case(
      id: id,
      name: name ?? this.name,
      number: number ?? this.number,
      court: court ?? this.court,
      type: type ?? this.type,

      docs: docs ?? this.docs,
      hearing: hearing ?? this.hearing,
      uncategorizedFiles: uncategorizedFiles ?? this.uncategorizedFiles,
      categories: categories ?? this.categories,
    );
  }

  /// Every file in this case, across the uncategorized bucket and all categories.
  Iterable<CaseFile> get allFiles sync* {
    yield* uncategorizedFiles;
    for (final cat in categories) {
      yield* cat.files;
    }
  }

  /// The file with [id] anywhere in this case, or null if it isn't present.
  CaseFile? fileById(int id) {
    for (final f in allFiles) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Returns a copy with [category] appended.
  Case addCategory(Category category) =>
      copyWith(categories: [...categories, category]);

  /// Returns a copy with [file] filed under [categoryName], or in the
  /// uncategorized bucket when no real category is named. Increments doc counts.
  Case addFile(CaseFile file, {String? categoryName}) {
    if (categoryName != null && categoryName != 'Uncategorized') {
      final updatedCategories = categories
          .map((cat) => cat.name == categoryName ? cat.addFile(file) : cat)
          .toList();
      return copyWith(categories: updatedCategories, docs: docs + 1);
    }
    return copyWith(
      uncategorizedFiles: [...uncategorizedFiles, file],
      docs: docs + 1,
    );
  }
}
