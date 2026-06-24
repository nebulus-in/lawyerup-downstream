import 'dart:async';

import '../models/legal_models.dart';
import '../services/docx_to_pdf_service.dart';
import '../services/document_scanner_service.dart';
import '../services/download_service.dart';

class LegalRepository {
  /// Broadcasts the current case list after every mutation, making this
  /// repository the single source of truth. BLoCs subscribe via [casesStream]
  /// so they never hold divergent copies of the data.
  final StreamController<List<Case>> _controller =
      StreamController<List<Case>>.broadcast();

  /// Emits the full case list whenever it changes. Late subscribers should seed
  /// their initial state from [getCases]; the stream replays nothing.
  Stream<List<Case>> get casesStream => _controller.stream;

  List<Case> _cases = [
    const Case(
      id: 1,
      name: 'Smith v. Johnson',
      number: '2024-CV-0847',
      court: 'Supreme Court, NY',
      type: 'CIVIL',

      docs: 24,
      hearing: 'Jun 28',
      uncategorizedFiles: [
        CaseFile(id: 1001, name: 'Initial_Consultation_Notes.docx', size: '1.2 MB', date: 'Jun 10'),
        CaseFile(id: 1002, name: 'Client_Retainer_Agreement.pdf', size: '450 KB', date: 'Jun 11'),
      ],
      categories: [
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
    const Case(
      id: 2,
      name: 'Mehta v. State Bank',
      number: '2024-CR-0312',
      court: 'High Court, Mumbai',
      type: 'CRIMINAL',

      docs: 17,
      hearing: 'Jun 25',
      uncategorizedFiles: [
        CaseFile(id: 2001, name: 'Fee_Receipt.pdf', size: '120 KB', date: 'May 20'),
      ],
      categories: [
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
    String? cnr,
    String? hearing,
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
      cnr: cnr,
      docs: 0,
      hearing: hearing ?? '-',
      categories: categories,
    );

    _cases = [..._cases, newCase];
    _broadcast();
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
    _broadcast();
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

  Future<List<Case>> renameCategory(int caseId, int categoryId, String newName) =>
      _apply(caseId, (c) => c.renameCategory(categoryId, newName));

  Future<List<Case>> deleteCategory(int caseId, int categoryId) =>
      _apply(caseId, (c) => c.removeCategory(categoryId));

  Future<List<Case>> uploadFile(
    int caseId,
    String? categoryName, {
    required String name,
    required String size,
    String? path,
  }) {
    return _addFile(caseId, categoryName, name: name, size: size, path: path);
  }

  /// Files a scanned PDF under [categoryName] (or the uncategorized bucket),
  /// keeping the on-disk path so the document can be reopened later.
  Future<List<Case>> addScannedDocument(
          int caseId, String? categoryName, ScannedDocument doc) =>
      _addFile(caseId, categoryName,
          name: doc.fileName, size: doc.sizeLabel, path: doc.path);

  /// Files a document downloaded from the in-app browser under [categoryName]
  /// (or the uncategorized bucket), keeping the on-disk path so it can be reopened.
  Future<List<Case>> addDownloadedFile(
          int caseId, String? categoryName, DownloadedFile doc) =>
      _addFile(caseId, categoryName,
          name: doc.fileName, size: doc.sizeLabel, path: doc.path);

  Future<List<Case>> saveOcrText({
    required int caseId,
    String? categoryName,
    required String text,
    required String fileName,
  }) {
    return _addFile(caseId, categoryName,
        name: fileName, size: '${(text.length / 1024).toStringAsFixed(1)} KB');
  }

  /// Files a DOCX-to-PDF conversion under [categoryName] (or the uncategorized
  /// bucket), keeping the on-disk path so the converted PDF can be reopened.
  Future<List<Case>> savePdfConversion(
          int caseId, String? categoryName, ConvertedPdf doc) =>
      _addFile(caseId, categoryName,
          name: doc.fileName, size: doc.sizeLabel, path: doc.path);

  /// Files a new [CaseFile] (built with a fresh id and a "Just now" date) under
  /// [categoryName]. The single place every "add a file to a case" path funnels
  /// through, whether the file is uploaded, scanned, downloaded, or OCR text.
  Future<List<Case>> _addFile(
    int caseId,
    String? categoryName, {
    required String name,
    required String size,
    String? path,
  }) async {
    // Add a small delay to simulate file processing and show skeleton loader
    await Future.delayed(const Duration(milliseconds: 800));
    
    final file = CaseFile(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      size: size,
      date: 'Just now',
      path: path,
    );
    return _apply(caseId, (c) => c.addFile(file, categoryName: categoryName));
  }

  Future<List<Case>> renameFile(int caseId, int fileId, String newName) =>
      _apply(caseId, (c) => c.renameFile(fileId, newName));

  Future<List<Case>> deleteFile(int caseId, int fileId) =>
      deleteFiles(caseId, [fileId]);

  Future<List<Case>> deleteFiles(int caseId, List<int> fileIds) =>
      _apply(caseId, (c) => c.removeFiles(fileIds.toSet()));

  Future<List<Case>> moveFile(int caseId, int fileId, String? targetCategoryName) =>
      moveFiles(caseId, [fileId], targetCategoryName);

  Future<List<Case>> moveFiles(int caseId, List<int> fileIds, String? targetCategoryName) =>
      _apply(caseId, (c) => c.moveFiles(fileIds.toSet(), targetCategoryName));

  /// Replaces the case matching [caseId] with [transform] applied to it,
  /// broadcasts the change, and returns the updated, unmodifiable case list.
  Future<List<Case>> _apply(int caseId, Case Function(Case) transform) async {
    _cases =
        _cases.map((c) => c.id == caseId ? transform(c) : c).toList();
    _broadcast();
    return List.unmodifiable(_cases);
  }

  void _broadcast() => _controller.add(List.unmodifiable(_cases));

  /// Closes the underlying stream. Call when the repository is torn down.
  void dispose() => _controller.close();
}
