import '../models/legal_models.dart';

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

  Future<List<Case>> uploadFile(int caseId, String? categoryName) async {
    final file = CaseFile(
      id: DateTime.now().millisecondsSinceEpoch,
      name: 'Simulated_Upload.pdf',
      size: '1.5 MB',
      date: 'Just now',
    );
    return _apply(caseId, (c) => c.addFile(file, categoryName: categoryName));
  }

  /// Replaces the case matching [caseId] with [transform] applied to it and
  /// returns the updated, unmodifiable case list.
  List<Case> _apply(int caseId, Case Function(Case) transform) {
    _cases =
        _cases.map((c) => c.id == caseId ? transform(c) : c).toList();
    return List.unmodifiable(_cases);
  }
}
