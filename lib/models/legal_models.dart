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

  Category copyWith({List<CaseFile>? files, int? docs}) {
    return Category(
      id: id,
      name: name,
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
