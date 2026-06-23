import '../models/legal_models.dart';
import '../services/document_scanner_service.dart';

class LegalRepository {
  List<Case> _cases = [
    Case(
      id: 1,
      name: 'Smith v. Johnson',
      number: '2024-CV-0847',
      court: 'Supreme Court, NY',
      type: 'CIVIL',

      docs: 24,
      hearing: 'Jun 28',
      uncategorizedFiles: const [
        CaseFile(id: 1001, name: 'Initial_Consultation_Notes.docx', size: '1.2 MB', date: 'Jun 10'),
        CaseFile(id: 1002, name: 'Client_Retainer_Agreement.pdf', size: '450 KB', date: 'Jun 11'),
      ],
      categories: const [
        Category(
          id: 101,
          name: 'Pleadings',
          docs: 8,

          files: [
            CaseFile(id: 1101, name: 'Complaint_SmithJohnson.pdf', size: '2.4 MB', date: 'Jun 21'),
            CaseFile(id: 1102, name: 'Answer_to_Complaint.pdf', size: '1.1 MB', date: 'Jun 23'),
          ],
        ),
        Category(
          id: 102,
          name: 'Evidence',
          docs: 6,

          files: [
            CaseFile(id: 1201, name: 'Photo_Evidence_A.jpg', size: '4.5 MB', date: 'Jun 15'),
            CaseFile(id: 1202, name: 'Bank_Statements_2023.pdf', size: '8.2 MB', date: 'Jun 16'),
          ],
        ),
        Category(
          id: 103,
          name: 'Correspondence',
          docs: 5,

          files: [
            CaseFile(id: 1301, name: 'Email_Thread_Opposing_Counsel.pdf', size: '600 KB', date: 'Jun 20'),
          ],
        ),
        Category(
          id: 104,
          name: 'Court Orders',
          docs: 5,

          files: [
            CaseFile(id: 1401, name: 'Court_Order_2024CV0847.pdf', size: '1.1 MB', date: 'Jun 18'),
          ],
        ),
      ],
    ),
    Case(
      id: 2,
      name: 'Mehta v. State Bank',
      number: '2024-CR-0312',
      court: 'High Court, Mumbai',
      type: 'CRIMINAL',

      docs: 17,
      hearing: 'Jun 25',
      uncategorizedFiles: const [
        CaseFile(id: 2001, name: 'Fee_Receipt.pdf', size: '120 KB', date: 'May 20'),
      ],
      categories: const [
        Category(
          id: 201,
          name: 'FIR',
          docs: 2,

          files: [
            CaseFile(id: 2101, name: 'FIR_Copy_Official.pdf', size: '3.1 MB', date: 'May 10'),
          ],
        ),
        Category(
          id: 202,
          name: 'Evidence',
          docs: 7,

          files: [
            CaseFile(id: 2201, name: 'CCTV_Footage_Transcript.docx', size: '2.2 MB', date: 'May 15'),
          ],
        ),
        Category(
          id: 203,
          name: 'Bail Documents',
          docs: 4,

          files: [
            CaseFile(id: 2301, name: 'Bail_Application_Draft.pdf', size: '900 KB', date: 'May 25'),
            CaseFile(id: 2302, name: 'Surety_Bonds.pdf', size: '1.5 MB', date: 'May 26'),
          ],
        ),
        Category(
          id: 204,
          name: 'Witness Statements',
          docs: 4,

          files: [
            CaseFile(id: 2401, name: 'Witness_Statement_OCR.pdf', size: '890 KB', date: 'Jun 20'),
          ],
        ),
      ],
    ),
  ];

  Future<List<Case>> getCases() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_cases);
  }

  Future<List<Case>> createCase({
    required String name,
    required String number,
    required String court,
    required String type,
    required List<String> folders,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final categories = <Category>[
      for (var i = 0; i < folders.length; i++)
        Category(
          id: now + 1 + i,
          name: folders[i],
          docs: 0,
        ),
    ];

    final newCase = Case(
      id: now,
      name: name,
      number: number.isEmpty ? 'Pending' : number,
      court: court.isEmpty ? 'TBD' : court,
      type: type,

      docs: 0,
      hearing: '-',
      categories: categories,
    );

    _cases = [..._cases, newCase];
    return List.unmodifiable(_cases);
  }

  Future<List<Case>> updateCaseDetails({
    required int caseId,
    required String name,
    required String number,
    required String court,
    required String type,
    required String hearing,
  }) async {
    return _apply(
      caseId,
      (c) => c.copyWith(
        name: name.isEmpty ? c.name : name,
        number: number.isEmpty ? 'Pending' : number,
        court: court.isEmpty ? 'TBD' : court,
        type: type,
        hearing: hearing,
      ),
    );
  }

  Future<List<Case>> deleteCase(int caseId) async {
    _cases = _cases.where((c) => c.id != caseId).toList();
    return List.unmodifiable(_cases);
  }

  Future<List<Case>> scheduleHearing(int caseId, String hearing) async {
    return _apply(caseId, (c) => c.copyWith(hearing: hearing));
  }

  Future<List<Case>> addCategory(int caseId, String name) async {
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      docs: 0,
    );
    return _apply(caseId, (c) => c.addCategory(category));
  }

  Future<List<Case>> renameCategory(int caseId, int categoryId, String newName) async {
    return _apply(caseId, (c) {
      final categories = c.categories.map((cat) {
        if (cat.id == categoryId) {
          return cat.copyWith(name: newName);
        }
        return cat;
      }).toList();
      return c.copyWith(categories: categories);
    });
  }

  Future<List<Case>> deleteCategory(int caseId, int categoryId) async {
    return _apply(caseId, (c) {
      final catToDelete = c.categories.firstWhere((cat) => cat.id == categoryId);
      final categories = c.categories.where((cat) => cat.id != categoryId).toList();
      final uncategorized = [...c.uncategorizedFiles, ...catToDelete.files];
      return c.copyWith(
        categories: categories,
        uncategorizedFiles: uncategorized,
      );
    });
  }

  Future<List<Case>> uploadFile(int caseId, String? categoryName) async {
    final file = CaseFile(
      id: DateTime.now().millisecondsSinceEpoch,
      name: 'Simulated_Upload.pdf',
      size: '1.5 MB',
      date: 'Just now',
    );
    return _apply(caseId, (c) => c.addFile(file, categoryName: categoryName));
  }

  /// Files a scanned PDF under [categoryName] (or the uncategorized bucket),
  /// keeping the on-disk path so the document can be reopened later.
  Future<List<Case>> addScannedDocument(
      int caseId, String? categoryName, ScannedDocument doc) async {
    final file = CaseFile(
      id: DateTime.now().millisecondsSinceEpoch,
      name: doc.fileName,
      size: doc.sizeLabel,
      date: 'Just now',
      path: doc.path,
    );
    return _apply(caseId, (c) => c.addFile(file, categoryName: categoryName));
  }

  Future<List<Case>> saveOcrText({
    required int caseId,
    String? categoryName,
    required String text,
    required String fileName,
  }) async {
    final file = CaseFile(
      id: DateTime.now().millisecondsSinceEpoch,
      name: fileName,
      size: '${(text.length / 1024).toStringAsFixed(1)} KB',
      date: 'Just now',
    );
    return _apply(caseId, (c) => c.addFile(file, categoryName: categoryName));
  }

  Future<List<Case>> renameFile(int caseId, int fileId, String newName) async {
    return _apply(caseId, (c) {
      final uncategorized = c.uncategorizedFiles.map((f) {
        return f.id == fileId ? f.copyWith(name: newName) : f;
      }).toList();
      
      final categories = c.categories.map((cat) {
        final files = cat.files.map((f) {
          return f.id == fileId ? f.copyWith(name: newName) : f;
        }).toList();
        return cat.copyWith(files: files);
      }).toList();
      
      return c.copyWith(
        uncategorizedFiles: uncategorized,
        categories: categories,
      );
    });
  }

  Future<List<Case>> deleteFile(int caseId, int fileId) async {
    return _apply(caseId, (c) {
      final uncategorized = c.uncategorizedFiles.where((f) => f.id != fileId).toList();
      final categories = c.categories.map((cat) {
        final files = cat.files.where((f) => f.id != fileId).toList();
        return cat.copyWith(files: files, docs: files.length);
      }).toList();
      
      int totalDocs = uncategorized.length;
      for (final cat in categories) {
        totalDocs += cat.files.length;
      }
          
      return c.copyWith(
        uncategorizedFiles: uncategorized,
        categories: categories,
        docs: totalDocs,
      );
    });
  }

  Future<List<Case>> moveFile(int caseId, int fileId, String? targetCategoryName) async {
    return _apply(caseId, (c) {
      CaseFile? targetFile;
      
      // Find and remove the file from its current location
      final uncategorizedOld = c.uncategorizedFiles.where((f) {
        if (f.id == fileId) {
          targetFile = f;
          return false;
        }
        return true;
      }).toList();
      
      final categoriesOld = c.categories.map((cat) {
        final files = cat.files.where((f) {
          if (f.id == fileId) {
            targetFile = f;
            return false;
          }
          return true;
        }).toList();
        return cat.copyWith(files: files, docs: files.length);
      }).toList();
      
      if (targetFile == null) return c;
      
      // Add it to the new location
      if (targetCategoryName == null || targetCategoryName == 'Uncategorized') {
        return c.copyWith(
          uncategorizedFiles: [...uncategorizedOld, targetFile!],
          categories: categoriesOld,
        );
      } else {
        final categoriesNew = categoriesOld.map((cat) {
          if (cat.name == targetCategoryName) {
            final files = [...cat.files, targetFile!];
            return cat.copyWith(files: files, docs: files.length);
          }
          return cat;
        }).toList();
        return c.copyWith(
          uncategorizedFiles: uncategorizedOld,
          categories: categoriesNew,
        );
      }
    });
  }

  /// Replaces the case matching [caseId] with [transform] applied to it and
  /// returns the updated, unmodifiable case list.
  List<Case> _apply(int caseId, Case Function(Case) transform) {
    _cases =
        _cases.map((c) => c.id == caseId ? transform(c) : c).toList();
    return List.unmodifiable(_cases);
  }
}
