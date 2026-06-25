import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
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
    on<CaseErrorDismissed>(_onCaseErrorDismissed);
    on<CaseCreated>(_onCaseCreated, transformer: droppable());
    on<CaseUpdated>(_onCaseUpdated, transformer: droppable());
    on<CaseDeleted>(_onCaseDeleted, transformer: droppable());
    on<CaseScheduled>(_onCaseScheduled, transformer: droppable());

    // Mutations from any BLoC reach us through the repository stream.
    _casesSubscription =
        _repository.casesStream.listen((cases) => add(_CasesUpdated(cases)));

    // Initial load (the broadcast stream replays nothing to late subscribers).
    add(LoadCases());
  }

  Future<void> _onLoadCases(LoadCases event, Emitter<CaseState> emit) async {
    emit(state.copyWith(status: CaseStatus.loading));
    try {
      _emitCases(emit, await _repository.getCases());
    } catch (e) {
      emit(state.copyWith(
        status: CaseStatus.failure,
        errorMessage: 'Could not load cases. Pull to retry.',
      ));
    }
  }

  /// Single point where the canonical case list is refreshed: whenever the
  /// repository broadcasts a change, regardless of which BLoC triggered it.
  void _onCasesUpdated(_CasesUpdated event, Emitter<CaseState> emit) =>
      _emitCases(emit, event.cases);

  void _onCaseErrorDismissed(CaseErrorDismissed event, Emitter<CaseState> emit) =>
      emit(state.copyWith(errorMessage: null));

  /// Emits a success state for [cases], recomputing the derived upcoming
  /// hearings — the one place that shape is built.
  void _emitCases(Emitter<CaseState> emit, List<Case> cases) {
    emit(state.copyWith(
      status: CaseStatus.success,
      cases: cases,
      upcomingHearings: Case.upcomingHearings(cases),
    ));
  }

  Future<void> _onCaseCreated(CaseCreated event, Emitter<CaseState> emit) =>
      _guard(
          emit,
          'Could not create the case. Please try again.',
          () => _repository.createCase(
                name: event.name,
                number: event.number,
                court: event.court,
                type: event.type,
                folders: event.folders,
                cnr: event.cnr,
                hearing: event.hearing,
              ));

  Future<void> _onCaseUpdated(CaseUpdated event, Emitter<CaseState> emit) =>
      _guard(
          emit,
          'Could not save the case. Please try again.',
          () => _repository.updateCaseDetails(
                caseId: event.caseId,
                name: event.name,
                number: event.number,
                court: event.court,
                type: event.type,
                hearing: event.hearing,
              ));

  Future<void> _onCaseDeleted(CaseDeleted event, Emitter<CaseState> emit) =>
      _guard(emit, 'Could not delete the case. Please try again.',
          () => _repository.deleteCase(event.caseId));

  Future<void> _onCaseScheduled(CaseScheduled event, Emitter<CaseState> emit) =>
      _guard(emit, 'Could not schedule the hearing. Please try again.',
          () => _repository.scheduleHearing(event.caseId, event.hearing));

  /// Runs a case command, surfacing [failMessage] as a transient error if it
  /// throws. The updated list flows back via the repository stream.
  Future<void> _guard(Emitter<CaseState> emit, String failMessage,
      Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      emit(state.copyWith(errorMessage: failMessage));
    }
  }

  @override
  Future<void> close() {
    _casesSubscription.cancel();
    return super.close();
  }
}
