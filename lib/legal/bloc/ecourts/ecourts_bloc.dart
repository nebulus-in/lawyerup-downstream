import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/ecourts/ecourts_api.dart';
import 'ecourts_event.dart';
import 'ecourts_state.dart';

class EcourtsBloc extends Bloc<EcourtsEvent, EcourtsState> {
  final EcourtsApi _api;

  EcourtsBloc(this._api) : super(const EcourtsState()) {
    on<EcourtsCauseListRequested>(_onCauseListRequested);
    on<EcourtsLookupRequested>(_onLookupRequested);
    on<EcourtsResetRequested>(_onResetRequested);
    // restartable: a new query cancels an in-flight search so a slower earlier
    // response can't land on top of newer results.
    on<EcourtsSearchSubmitted>(_onSearchSubmitted, transformer: restartable());

    add(const EcourtsCauseListRequested());
  }

  Future<void> _onCauseListRequested(
    EcourtsCauseListRequested event,
    Emitter<EcourtsState> emit,
  ) async {
    emit(state.copyWith(causeListLoading: true));
    try {
      final list = await _api.causeList(CauseListQuery(date: DateTime.now()));
      emit(state.copyWith(causeList: list, causeListLoading: false));
    } catch (_) {
      emit(state.copyWith(causeListLoading: false));
    }
  }

  Future<void> _onLookupRequested(
    EcourtsLookupRequested event,
    Emitter<EcourtsState> emit,
  ) async {
    final cnr = Cnr.normalize(event.raw);
    if (!Cnr.isValid(cnr)) {
      emit(state.copyWith(
        status: EcourtsStatus.invalid,
        queryCnr: cnr,
        result: null,
        message: 'A CNR is 16 letters and digits — check for a missing one.',
      ));
      return;
    }

    emit(state.copyWith(
        status: EcourtsStatus.loading, queryCnr: cnr, message: null));
    try {
      final result = await _api.caseByCnr(cnr);
      final recent = [
        cnr,
        ...state.recent.where((r) => r != cnr),
      ].take(4).toList();
      emit(state.copyWith(
          status: EcourtsStatus.success, result: result, recent: recent));
    } on InvalidCnrException catch (e) {
      emit(state.copyWith(
          status: EcourtsStatus.invalid, result: null, message: e.message));
    } on CaseNotFoundException {
      emit(state.copyWith(status: EcourtsStatus.notFound, result: null));
    } on EcourtsException catch (e) {
      emit(state.copyWith(
          status: EcourtsStatus.error, result: null, message: e.message));
    }
  }

  Future<void> _onSearchSubmitted(
    EcourtsSearchSubmitted event,
    Emitter<EcourtsState> emit,
  ) async {
    final c = event.criteria;
    if (!c.isRunnable) {
      // Nothing to match on yet — rest on the board, but keep the scope/sort the
      // user has set so picking a scope before typing doesn't snap back.
      emit(state.copyWith(
        searchCriteria: c,
        searchPhase: SearchPhase.idle,
        searchHits: const [],
        searchError: '',
      ));
      return;
    }

    // Store the criteria up front so the field, chips and filter sheet reflect
    // it while the search is still in flight. Keep a short trail of recent
    // queries (text only), most recent first, deduped — same shape as [recent].
    final text = c.text.trim();
    final recents = text.isEmpty
        ? state.recentSearches
        : [
            text,
            ...state.recentSearches
                .where((r) => r.toLowerCase() != text.toLowerCase()),
          ].take(4).toList();
    emit(state.copyWith(
      searchCriteria: c,
      searchPhase: SearchPhase.loading,
      searchError: '',
      recentSearches: recents,
    ));
    try {
      final result = await _api.searchCases(_queryFrom(c));
      emit(state.copyWith(
          searchHits: result.hits, searchPhase: SearchPhase.done));
    } on EcourtsException catch (e) {
      emit(state.copyWith(
        searchPhase: SearchPhase.error,
        searchHits: const [],
        searchError: e.message,
      ));
    }
  }

  /// Translates UI [SearchCriteria] into the registry's [CaseSearchQuery]:
  /// the scope picks which text field carries the query, and the sort field
  /// maps onto the registry's column names.
  static CaseSearchQuery _queryFrom(SearchCriteria c) {
    final text = c.text.trim();
    final t = text.isEmpty ? null : text;
    final sortBy = switch (c.sortField) {
      SortField.relevance => null,
      SortField.nextHearing => 'nextHearingDate',
      SortField.filingDate => 'filingDate',
      SortField.decisionDate => 'decisionDate',
    };
    return CaseSearchQuery(
      query: c.scope == SearchScope.all ? t : null,
      advocateName: c.scope == SearchScope.advocate ? t : null,
      judgeName: c.scope == SearchScope.judge ? t : null,
      partyName: c.scope == SearchScope.party ? t : null,
      caseStatuses: c.statuses.isEmpty ? null : c.statuses.toList(),
      nextHearingFrom: c.hearingFrom,
      nextHearingTo: c.hearingTo,
      sortBy: sortBy,
      sortOrder: sortBy == null ? null : (c.sortDescending ? 'desc' : 'asc'),
    );
  }

  void _onResetRequested(
    EcourtsResetRequested event,
    Emitter<EcourtsState> emit,
  ) {
    emit(state.copyWith(
      status: EcourtsStatus.idle,
      result: null,
      queryCnr: '',
      message: null,
    ));
  }

  @override
  Future<void> close() {
    _api.dispose();
    return super.close();
  }
}
