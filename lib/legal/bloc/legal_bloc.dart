import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../models/legal_models.dart';

part 'legal_event.dart';
part 'legal_state.dart';

class LegalBloc extends Bloc<LegalEvent, LegalState> {
  LegalBloc()
      : super(LegalState(
          cases: [
            Case(
              id: 1,
              name: 'Smith v. Johnson',
              number: '2024-CV-0847',
              court: 'Supreme Court, NY',
              type: 'CIVIL',
              typeColor: const Color(0xFF1463E0),
              typeBg: const Color(0xFFE8F0FE),
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
                  color: Color(0xFF1463E0),
                  bg: Color(0xFFE8F0FE),
                  files: [
                    CaseFile(id: 1101, name: 'Complaint_SmithJohnson.pdf', size: '2.4 MB', date: 'Jun 21'),
                    CaseFile(id: 1102, name: 'Answer_to_Complaint.pdf', size: '1.1 MB', date: 'Jun 23'),
                  ],
                ),
                Category(
                  id: 102,
                  name: 'Evidence',
                  docs: 6,
                  color: Color(0xFF1A8A4A),
                  bg: Color(0xFFE8F5EE),
                  files: [
                    CaseFile(id: 1201, name: 'Photo_Evidence_A.jpg', size: '4.5 MB', date: 'Jun 15'),
                    CaseFile(id: 1202, name: 'Bank_Statements_2023.pdf', size: '8.2 MB', date: 'Jun 16'),
                  ],
                ),
                Category(
                  id: 103,
                  name: 'Correspondence',
                  docs: 5,
                  color: Color(0xFF9B59B6),
                  bg: Color(0xFFF5EEFF),
                  files: [
                    CaseFile(id: 1301, name: 'Email_Thread_Opposing_Counsel.pdf', size: '600 KB', date: 'Jun 20'),
                  ],
                ),
                Category(
                  id: 104,
                  name: 'Court Orders',
                  docs: 5,
                  color: Color(0xFFE07A14),
                  bg: Color(0xFFFFF4EC),
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
              typeColor: const Color(0xFFE07A14),
              typeBg: const Color(0xFFFFF4EC),
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
                  color: Color(0xFFC0392B),
                  bg: Color(0xFFFCE8E8),
                  files: [
                    CaseFile(id: 2101, name: 'FIR_Copy_Official.pdf', size: '3.1 MB', date: 'May 10'),
                  ],
                ),
                Category(
                  id: 202,
                  name: 'Evidence',
                  docs: 7,
                  color: Color(0xFF1A8A4A),
                  bg: Color(0xFFE8F5EE),
                  files: [
                    CaseFile(id: 2201, name: 'CCTV_Footage_Transcript.docx', size: '2.2 MB', date: 'May 15'),
                  ],
                ),
                Category(
                  id: 203,
                  name: 'Bail Documents',
                  docs: 4,
                  color: Color(0xFF1463E0),
                  bg: Color(0xFFE8F0FE),
                  files: [
                    CaseFile(id: 2301, name: 'Bail_Application_Draft.pdf', size: '900 KB', date: 'May 25'),
                    CaseFile(id: 2302, name: 'Surety_Bonds.pdf', size: '1.5 MB', date: 'May 26'),
                  ],
                ),
                Category(
                  id: 204,
                  name: 'Witness Statements',
                  docs: 4,
                  color: Color(0xFF9B59B6),
                  bg: Color(0xFFF5EEFF),
                  files: [
                    CaseFile(id: 2401, name: 'Witness_Statement_OCR.pdf', size: '890 KB', date: 'Jun 20'),
                  ],
                ),
              ],
            ),
          ],
        )) {
    on<TabChanged>((event, emit) {
      emit(state.copyWith(activeTab: event.tab, selectedCaseId: null, selectedCategoryId: null));
    });

    on<CaseSelected>((event, emit) {
      emit(state.copyWith(selectedCaseId: event.caseId, selectedCategoryId: null));
    });

    on<CategorySelected>((event, emit) {
      emit(state.copyWith(selectedCategoryId: event.categoryId));
    });

    on<DateSelected>((event, emit) {
      emit(state.copyWith(selectedDate: event.date));
    });

    on<CaseCreated>((event, emit) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final palette = {
        'CIVIL': [const Color(0xFF1463E0), const Color(0xFFE8F0FE)],
        'CRIMINAL': [const Color(0xFFE07A14), const Color(0xFFFFF4EC)],
        'FAMILY': [const Color(0xFF9B59B6), const Color(0xFFF5EEFF)],
        'CORPORATE': [const Color(0xFF1A8A4A), const Color(0xFFE8F5EE)],
      };
      final colors = palette[event.type] ?? [const Color(0xFF718096), const Color(0xFFF0F2F5)];

      final newCase = Case(
        id: now,
        name: event.name,
        number: event.number.isEmpty ? 'Pending' : event.number,
        court: event.court.isEmpty ? 'TBD' : event.court,
        type: event.type,
        typeColor: colors[0],
        typeBg: colors[1],
        docs: 0,
        hearing: '—',
        categories: [
          Category(id: now + 1, name: 'Pleadings', docs: 0, color: const Color(0xFF1463E0), bg: const Color(0xFFE8F0FE)),
          Category(id: now + 2, name: 'Evidence', docs: 0, color: const Color(0xFF1A8A4A), bg: const Color(0xFFE8F5EE)),
          Category(id: now + 3, name: 'Correspondence', docs: 0, color: const Color(0xFF9B59B6), bg: const Color(0xFFF5EEFF)),
        ],
      );
      emit(state.copyWith(cases: [...state.cases, newCase]));
    });

    on<CategoryAdded>((event, emit) {
      final palette = [
        [const Color(0xFF1463E0), const Color(0xFFE8F0FE)],
        [const Color(0xFF1A8A4A), const Color(0xFFE8F5EE)],
        [const Color(0xFF9B59B6), const Color(0xFFF5EEFF)],
        [const Color(0xFFE07A14), const Color(0xFFFFF4EC)],
        [const Color(0xFFC0392B), const Color(0xFFFCE8E8)],
      ];

      final updatedCases = state.cases.map((c) {
        if (c.id == event.caseId) {
          final colors = palette[c.categories.length % palette.length];
          return c.copyWith(
            categories: [
              ...c.categories,
              Category(
                id: DateTime.now().millisecondsSinceEpoch,
                name: event.name,
                docs: 0,
                color: colors[0],
                bg: colors[1],
              )
            ],
          );
        }
        return c;
      }).toList();
      emit(state.copyWith(cases: updatedCases));
    });

    on<FileUploaded>((event, emit) {
      final newFile = CaseFile(
        id: DateTime.now().millisecondsSinceEpoch,
        name: 'Simulated_Upload.pdf',
        size: '1.5 MB',
        date: 'Just now',
      );

      final updatedCases = state.cases.map((c) {
        if (c.id == event.caseId) {
          if (event.categoryName != null && event.categoryName != 'Uncategorized') {
            final updatedCats = c.categories.map((cat) {
              if (cat.name == event.categoryName) {
                return cat.copyWith(
                  docs: cat.docs + 1,
                  files: [...cat.files, newFile],
                );
              }
              return cat;
            }).toList();
            return c.copyWith(categories: updatedCats, docs: c.docs + 1);
          } else {
            return c.copyWith(
              uncategorizedFiles: [...c.uncategorizedFiles, newFile],
              docs: c.docs + 1,
            );
          }
        }
        return c;
      }).toList();
      emit(state.copyWith(cases: updatedCases));
    });
  }
}
