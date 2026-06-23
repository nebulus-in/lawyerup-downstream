import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../models/legal_models.dart';
import '../../../repositories/legal_repository.dart';

part 'case_event.dart';
part 'case_state.dart';

/// Manages case data and operations (CRUD, scheduling, hearings).
///
/// Owns the canonical [cases] list for the UI. Case-level commands delegate to
/// the repository and surface only errors; the resulting data flows back in via
/// the repository's broadcast stream, so this BLoC stays in sync with folder
/// and file mutations made through [CategoryBloc] and [FileBloc].
class CaseBloc extends Bloc<CaseEvent, CaseState> {
  final LegalRepository _repository;
  late final StreamSubscription<List<Case>> _casesSubscription;

  CaseBloc({required LegalRepository repository})
      : _repository = repository,
        super(const CaseState()) {
    on<LoadCases>(_onLoadCases);
    on<_CasesUpdated>(_onCasesUpdated);
    on<CaseCreated>(_onCaseCreated);
    on<CaseUpdated>(_onCaseUpdated);
    on<CaseDeleted>(_onCaseDeleted);
    on<CaseScheduled>(_onCaseScheduled);

    // Mutations from any BLoC reach us through the repository stream.
    _casesSubscription =
        _repository.casesStream.listen((cases) => add(_CasesUpdated(cases)));

    // Initial load (the broadcast stream replays nothing to late subscribers).
    add(LoadCases());
  }

  Future<void> _onLoadCases(LoadCases event, Emitter<CaseState> emit) async {
    emit(state.copyWith(status: CaseStatus.loading));
    try {
      final cases = await _repository.getCases();
      emit(state.copyWith(
        status: CaseStatus.success,
        cases: cases,
        upcomingHearings: Case.upcomingHearings(cases),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CaseStatus.failure,
        errorMessage: 'Could not load cases. Pull to retry.',
      ));
    }
  }

  /// Single point where the canonical case list is refreshed: whenever the
  /// repository broadcasts a change, regardless of which BLoC triggered it.
  void _onCasesUpdated(_CasesUpdated event, Emitter<CaseState> emit) {
    emit(state.copyWith(
      status: CaseStatus.success,
      cases: event.cases,
      upcomingHearings: Case.upcomingHearings(event.cases),
    ));
  }

  Future<void> _onCaseCreated(CaseCreated event, Emitter<CaseState> emit) async {
    try {
      await _repository.createCase(
        name: event.name,
        number: event.number,
        court: event.court,
        type: event.type,
        folders: event.folders,
      );
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not create the case. Please try again.'));
    }
  }

  Future<void> _onCaseUpdated(CaseUpdated event, Emitter<CaseState> emit) async {
    try {
      await _repository.updateCaseDetails(
        caseId: event.caseId,
        name: event.name,
        number: event.number,
        court: event.court,
        type: event.type,
        hearing: event.hearing,
      );
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not save the case. Please try again.'));
    }
  }

  Future<void> _onCaseDeleted(CaseDeleted event, Emitter<CaseState> emit) async {
    try {
      await _repository.deleteCase(event.caseId);
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not delete the case. Please try again.'));
    }
  }

  Future<void> _onCaseScheduled(
      CaseScheduled event, Emitter<CaseState> emit) async {
    try {
      await _repository.scheduleHearing(event.caseId, event.hearing);
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not schedule the hearing. Please try again.'));
    }
  }

  @override
  Future<void> close() {
    _casesSubscription.cancel();
    return super.close();
  }
}
