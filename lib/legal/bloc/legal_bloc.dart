import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/legal_models.dart';
import '../../repositories/legal_repository.dart';
import '../../services/document_scanner_service.dart';

part 'legal_event.dart';
part 'legal_state.dart';

class LegalBloc extends Bloc<LegalEvent, LegalState> {
  final LegalRepository _repository;

  static final DateTime _kToday = DateTime(2026, 6, 22);

  LegalBloc({required LegalRepository repository})
      : _repository = repository,
        super(const LegalState()) {
    on<LoadCases>(_onLoadCases);
    on<TabChanged>(_onTabChanged);
    on<CaseSelected>(_onCaseSelected);
    on<CategorySelected>(_onCategorySelected);
    on<DateSelected>(_onDateSelected);
    on<LongPressedIdChanged>(_onLongPressedIdChanged);
    on<CaseCreated>(_onCaseCreated);
    on<CaseUpdated>(_onCaseUpdated);
    on<CaseDeleted>(_onCaseDeleted);
    on<CaseScheduled>(_onCaseScheduled);
    on<CategoryAdded>(_onCategoryAdded);
    on<CategoryRenamed>(_onCategoryRenamed);
    on<CategoryDeleted>(_onCategoryDeleted);
    on<FileUploaded>(_onFileUploaded);
    on<DocumentScanned>(_onDocumentScanned);
    on<OcrTextSaved>(_onOcrTextSaved);
    on<FileRenamed>(_onFileRenamed);
    on<FileDeleted>(_onFileDeleted);
    on<FileMoved>(_onFileMoved);
    
    // Initial load
    add(LoadCases());
  }

  Future<void> _onLoadCases(LoadCases event, Emitter<LegalState> emit) async {
    emit(state.copyWith(status: LegalStatus.loading));
    try {
      final cases = await _repository.getCases();
      emit(state.copyWith(
        status: LegalStatus.success,
        cases: cases,
        upcomingHearings: _computeUpcoming(cases),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LegalStatus.failure,
        errorMessage: 'Could not load cases. Pull to retry.',
      ));
    }
  }

  void _onTabChanged(TabChanged event, Emitter<LegalState> emit) {
    emit(state.copyWith(
      activeTab: event.tab,
      selectedCaseId: null,
      selectedCategoryId: null,
      selectedDate: null,
      longPressedId: null,
    ));
  }

  void _onCaseSelected(CaseSelected event, Emitter<LegalState> emit) {
    emit(state.copyWith(
      selectedCaseId: event.caseId, 
      selectedCategoryId: null,
      longPressedId: null,
    ));
  }

  void _onCategorySelected(CategorySelected event, Emitter<LegalState> emit) {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      longPressedId: null,
    ));
  }

  void _onDateSelected(DateSelected event, Emitter<LegalState> emit) {
    emit(state.copyWith(selectedDate: event.date));
  }

  void _onLongPressedIdChanged(LongPressedIdChanged event, Emitter<LegalState> emit) {
    emit(state.copyWith(longPressedId: event.id));
  }

  Future<void> _onCaseCreated(CaseCreated event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.createCase(
        name: event.name,
        number: event.number,
        court: event.court,
        type: event.type,
        folders: event.folders,
      );
      emit(state.copyWith(
        cases: cases,
        upcomingHearings: _computeUpcoming(cases),
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not create the case. Please try again.'));
    }
  }

  Future<void> _onCaseUpdated(CaseUpdated event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.updateCaseDetails(
        caseId: event.caseId,
        name: event.name,
        number: event.number,
        court: event.court,
        type: event.type,
        hearing: event.hearing,
      );
      emit(state.copyWith(
        cases: cases,
        upcomingHearings: _computeUpcoming(cases),
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not save the case. Please try again.'));
    }
  }

  Future<void> _onCaseDeleted(CaseDeleted event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.deleteCase(event.caseId);
      emit(state.copyWith(
        cases: cases,
        selectedCaseId: state.selectedCaseId == event.caseId ? null : state.selectedCaseId,
        upcomingHearings: _computeUpcoming(cases),
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not delete the case. Please try again.'));
    }
  }

  Future<void> _onCaseScheduled(CaseScheduled event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.scheduleHearing(event.caseId, event.hearing);
      emit(state.copyWith(
        cases: cases,
        upcomingHearings: _computeUpcoming(cases),
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not schedule the hearing. Please try again.'));
    }
  }

  Future<void> _onCategoryAdded(CategoryAdded event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.addCategory(event.caseId, event.name);
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not add the folder. Please try again.'));
    }
  }

  Future<void> _onCategoryRenamed(CategoryRenamed event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.renameCategory(event.caseId, event.categoryId, event.newName);
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not rename the folder. Please try again.'));
    }
  }

  Future<void> _onCategoryDeleted(CategoryDeleted event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.deleteCategory(event.caseId, event.categoryId);
      emit(state.copyWith(
        cases: cases,
        selectedCategoryId: state.selectedCategoryId == event.categoryId ? null : state.selectedCategoryId,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not delete the folder. Please try again.'));
    }
  }

  Future<void> _onFileUploaded(FileUploaded event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.uploadFile(event.caseId, event.categoryName);
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not upload the file. Please try again.'));
    }
  }

  Future<void> _onDocumentScanned(
      DocumentScanned event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.addScannedDocument(
          event.caseId, event.categoryName, event.document);
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not save the scanned document. Please try again.'));
    }
  }

  Future<void> _onOcrTextSaved(
      OcrTextSaved event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.saveOcrText(
        caseId: event.caseId,
        categoryName: event.categoryName,
        text: event.text,
        fileName: event.fileName,
      );
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not save OCR text. Please try again.'));
    }
  }

  Future<void> _onFileRenamed(FileRenamed event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.renameFile(event.caseId, event.fileId, event.newName);
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not rename the file. Please try again.'));
    }
  }

  Future<void> _onFileDeleted(FileDeleted event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.deleteFile(event.caseId, event.fileId);
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not delete the file. Please try again.'));
    }
  }

  Future<void> _onFileMoved(FileMoved event, Emitter<LegalState> emit) async {
    try {
      final cases = await _repository.moveFile(event.caseId, event.fileId, event.targetCategoryName);
      emit(state.copyWith(cases: cases));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Could not move the file. Please try again.'));
    }
  }

  List<Case> _computeUpcoming(List<Case> cases) {
    final upcoming = <(Case, DateTime)>[];
    for (final c in cases) {
      final date = c.hearingDate;
      if (date == null || date.isBefore(_kToday)) continue;
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
        if (days.length == 2) break;
        days.add(entry.$2);
      }
      result.add(entry.$1);
    }
    return result;
  }
}
