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
  /// Sentinel category name meaning "no real folder" — files filed under this
  /// name (or a null name) live in the case's [Case.uncategorizedFiles] bucket.
  /// Kept separate from any user-facing label so display text can change freely.
  static const uncategorized = 'Uncategorized';

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
    if (categoryName != null && categoryName != Category.uncategorized) {
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

  /// Returns a copy with the file matching [id] renamed to [name], wherever it
  /// lives in the case.
  Case renameFile(int id, String name) {
    CaseFile rename(CaseFile f) => f.id == id ? f.copyWith(name: name) : f;
    return copyWith(
      uncategorizedFiles: uncategorizedFiles.map(rename).toList(),
      categories: categories
          .map((cat) => cat.copyWith(files: cat.files.map(rename).toList()))
          .toList(),
    );
  }

  /// Returns a copy with the files matching [ids] removed everywhere, with the
  /// per-folder and case-level doc counts recomputed from the survivors.
  Case removeFiles(Set<int> ids) {
    final uncategorized =
        uncategorizedFiles.where((f) => !ids.contains(f.id)).toList();
    final updatedCategories = categories.map((cat) {
      final files = cat.files.where((f) => !ids.contains(f.id)).toList();
      return cat.copyWith(files: files, docs: files.length);
    }).toList();
    final total = uncategorized.length +
        updatedCategories.fold<int>(0, (n, cat) => n + cat.files.length);
    return copyWith(
      uncategorizedFiles: uncategorized,
      categories: updatedCategories,
      docs: total,
    );
  }

  /// Returns a copy with the files matching [ids] moved into [categoryName] (or
  /// the uncategorized bucket when no real category is named). Per-folder doc
  /// counts stay in sync; the case total is unchanged.
  Case moveFiles(Set<int> ids, String? categoryName) {
    final moved = <CaseFile>[];
    List<CaseFile> take(List<CaseFile> files) => files.where((f) {
          if (ids.contains(f.id)) {
            moved.add(f);
            return false;
          }
          return true;
        }).toList();

    final uncategorizedRest = take(uncategorizedFiles);
    final categoriesRest = categories
        .map((cat) {
          final files = take(cat.files);
          return cat.copyWith(files: files, docs: files.length);
        })
        .toList();

    if (moved.isEmpty) return this;

    if (categoryName == null || categoryName == Category.uncategorized) {
      return copyWith(
        uncategorizedFiles: [...uncategorizedRest, ...moved],
        categories: categoriesRest,
      );
    }
    final categoriesNew = categoriesRest.map((cat) {
      if (cat.name != categoryName) return cat;
      final files = [...cat.files, ...moved];
      return cat.copyWith(files: files, docs: files.length);
    }).toList();
    return copyWith(
      uncategorizedFiles: uncategorizedRest,
      categories: categoriesNew,
    );
  }

  /// Returns a copy with the category matching [id] renamed to [name].
  Case renameCategory(int id, String name) => copyWith(
        categories: categories
            .map((cat) => cat.id == id ? cat.copyWith(name: name) : cat)
            .toList(),
      );

  /// Returns a copy with the category matching [id] removed; its files fall back
  /// into the uncategorized bucket.
  Case removeCategory(int id) {
    final removed = categories.firstWhere((cat) => cat.id == id);
    return copyWith(
      categories: categories.where((cat) => cat.id != id).toList(),
      uncategorizedFiles: [...uncategorizedFiles, ...removed.files],
    );
  }
}
