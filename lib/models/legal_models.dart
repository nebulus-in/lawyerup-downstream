import 'package:equatable/equatable.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The app's "today" (date-only). Single source of truth so the calendar and
/// the upcoming-hearings list agree on what counts as future.
final legalToday = _dateOnly(DateTime.now());

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

  factory CaseFile.fromJson(Map<String, dynamic> json) => CaseFile(
        id: json['id'] as int,
        name: json['name'] as String,
        size: json['size'] as String,
        date: json['date'] as String,
        path: json['path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'date': date,
        if (path != null) 'path': path,
      };

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

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        docs: json['docs'] as int,
        files: (json['files'] as List<dynamic>?)
                ?.map((e) => CaseFile.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'docs': docs,
        'files': files.map((e) => e.toJson()).toList(),
      };

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

  /// The 16-character CNR if this case was imported from eCourts, or null for
  /// manually created cases. Used to surface the "View on eCourts" card in the
  /// case detail view.
  final String? cnr;

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
    this.cnr,
    required this.docs,
    required this.hearing,
    this.uncategorizedFiles = const [],
    this.categories = const [],
  });

  factory Case.fromJson(Map<String, dynamic> json) => Case(
        id: json['id'] as int,
        name: json['name'] as String,
        number: json['number'] as String,
        court: json['court'] as String,
        type: json['type'] as String,
        cnr: json['cnr'] as String?,
        docs: json['docs'] as int,
        hearing: json['hearing'] as String,
        uncategorizedFiles: (json['uncategorizedFiles'] as List<dynamic>?)
                ?.map((e) => CaseFile.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        categories: (json['categories'] as List<dynamic>?)
                ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'number': number,
        'court': court,
        'type': type,
        if (cnr != null) 'cnr': cnr,
        'docs': docs,
        'hearing': hearing,
        'uncategorizedFiles': uncategorizedFiles.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
      };

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Whether this case has a scheduled hearing (vs. the `'-'` placeholder).
  bool get isScheduled => hearing != '-' && hearing.isNotEmpty;

  /// The `hearing` display string parsed to a date, or null if unscheduled.
  DateTime? get hearingDate => parseHearing(hearing);

  static DateTime? parseHearing(String h) {
    final parts = h.replaceAll(',', '').split(' ');
    if (parts.length < 2) return null;
    final m = _monthAbbr.indexOf(parts[0]);
    final d = int.tryParse(parts[1]);
    if (m < 0 || d == null) return null;
    // Legacy strings stored before hearings carried a year fall back to the
    // current year.
    final y = parts.length >= 3 ? int.tryParse(parts[2]) : null;
    return DateTime(y ?? legalToday.year, m + 1, d);
  }

  static String formatHearing(DateTime dt) =>
      '${_monthAbbr[dt.month - 1]} ${dt.day}, ${dt.year}';

  /// Cases with a hearing scheduled for [today] (date-only) or later, ordered
  /// by date then name. [today] defaults to the app's pinned [legalToday] so
  /// this list agrees with what the calendar marks as upcoming.
  ///
  /// Domain logic for "upcoming hearings" lives here rather than in a BLoC so
  /// the orchestration layer stays thin.
  static List<Case> upcomingHearings(List<Case> cases, {DateTime? today}) {
    final cutoff = _dateOnly(today ?? legalToday);
    final upcoming = <(Case, DateTime)>[];

    for (final c in cases) {
      final date = c.hearingDate;
      if (date == null || date.isBefore(cutoff)) continue;
      upcoming.add((c, date));
    }

    upcoming.sort((a, b) {
      final byDate = a.$2.compareTo(b.$2);
      return byDate != 0 ? byDate : a.$1.name.compareTo(b.$1.name);
    });

    return [for (final entry in upcoming) entry.$1];
  }

  @override
  List<Object?> get props => [
        id,
        name,
        number,
        court,
        type,
        cnr,
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
    Object? cnr = _undefined,
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
      cnr: identical(cnr, _undefined) ? this.cnr : cnr as String?,
      docs: docs ?? this.docs,
      hearing: hearing ?? this.hearing,
      uncategorizedFiles: uncategorizedFiles ?? this.uncategorizedFiles,
      categories: categories ?? this.categories,
    );
  }

  static const Object _undefined = Object();

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
