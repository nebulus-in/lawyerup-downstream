import 'package:equatable/equatable.dart';

import '../../../services/ecourts/ecourts_models.dart';

/// Where a CNR lookup currently stands.
enum EcourtsStatus { idle, loading, success, notFound, invalid, error }

/// Where the party/case search in the idle view currently stands. Kept apart
/// from [EcourtsStatus]: search lives alongside the cause-list board, and
/// opening a chosen result hands off to the CNR lookup ([EcourtsStatus]).
enum SearchPhase { idle, loading, done, error }

/// Which field the search text is matched against. [all] is the full-text
/// query; [party] covers both petitioners and respondents (litigants).
enum SearchScope { all, advocate, judge, party }

/// How results are ordered. [relevance] leaves the order to the registry.
enum SortField { relevance, nextHearing, filingDate, decisionDate }

/// Everything that shapes a search: the text and what it matches against, plus
/// the filters and sort. Held in state so results survive opening a case and
/// returning, and so the filter sheet and chips can reflect what's active.
class SearchCriteria extends Equatable {
  final String text;
  final SearchScope scope;

  /// Case-status codes to keep, e.g. `{'PENDING'}`. Empty means any status.
  final Set<String> statuses;
  final DateTime? hearingFrom;
  final DateTime? hearingTo;
  final SortField sortField;
  final bool sortDescending;

  const SearchCriteria({
    this.text = '',
    this.scope = SearchScope.all,
    this.statuses = const {},
    this.hearingFrom,
    this.hearingTo,
    this.sortField = SortField.relevance,
    this.sortDescending = true,
  });

  bool get hasHearingRange => hearingFrom != null || hearingTo != null;

  /// Whether there's enough to run a search. Sort alone doesn't count — it only
  /// orders matches a query has already produced.
  bool get isRunnable =>
      text.trim().isNotEmpty || statuses.isNotEmpty || hasHearingRange;

  /// Active narrowing filters (excludes scope and the text), for the badge.
  int get filterCount =>
      statuses.length +
      (hasHearingRange ? 1 : 0) +
      (sortField != SortField.relevance ? 1 : 0);

  SearchCriteria copyWith({
    String? text,
    SearchScope? scope,
    Set<String>? statuses,
    Object? hearingFrom = _undefined,
    Object? hearingTo = _undefined,
    SortField? sortField,
    bool? sortDescending,
  }) =>
      SearchCriteria(
        text: text ?? this.text,
        scope: scope ?? this.scope,
        statuses: statuses ?? this.statuses,
        hearingFrom: identical(hearingFrom, _undefined)
            ? this.hearingFrom
            : hearingFrom as DateTime?,
        hearingTo: identical(hearingTo, _undefined)
            ? this.hearingTo
            : hearingTo as DateTime?,
        sortField: sortField ?? this.sortField,
        sortDescending: sortDescending ?? this.sortDescending,
      );

  @override
  List<Object?> get props =>
      [text, scope, statuses, hearingFrom, hearingTo, sortField, sortDescending];
}

/// State for the eCourts Case Status screen: the active lookup, the result, the
/// day's cause list, and a short trail of recent lookups.
class EcourtsState extends Equatable {
  final EcourtsStatus status;
  final EcourtsCase? result;

  /// The normalized CNR the result belongs to (also drives the not-found view).
  final String queryCnr;

  final List<CauseListEntry> causeList;
  final bool causeListLoading;

  /// Recently resolved CNRs, most recent first, capped at four.
  final List<String> recent;

  /// One-shot human-readable detail for the invalid/error states.
  final String? message;

  final SearchCriteria searchCriteria;
  final SearchPhase searchPhase;
  final List<CaseSearchHit> searchHits;

  /// Human-readable detail for [SearchPhase.error]; empty otherwise.
  final String searchError;

  /// Recent register search queries (text only), most recent first, capped at
  /// four. Kept apart from [recent], which holds resolved CNRs.
  final List<String> recentSearches;

  const EcourtsState({
    this.status = EcourtsStatus.idle,
    this.result,
    this.queryCnr = '',
    this.causeList = const [],
    this.causeListLoading = false,
    this.recent = const [],
    this.message,
    this.searchCriteria = const SearchCriteria(),
    this.searchPhase = SearchPhase.idle,
    this.searchHits = const [],
    this.searchError = '',
    this.recentSearches = const [],
  });

  @override
  List<Object?> get props => [
        status,
        result,
        queryCnr,
        causeList,
        causeListLoading,
        recent,
        message,
        searchCriteria,
        searchPhase,
        searchHits,
        searchError,
        recentSearches,
      ];

  EcourtsState copyWith({
    EcourtsStatus? status,
    Object? result = _undefined,
    String? queryCnr,
    List<CauseListEntry>? causeList,
    bool? causeListLoading,
    List<String>? recent,
    Object? message = _undefined,
    SearchCriteria? searchCriteria,
    SearchPhase? searchPhase,
    List<CaseSearchHit>? searchHits,
    String? searchError,
    List<String>? recentSearches,
  }) {
    return EcourtsState(
      status: status ?? this.status,
      result: identical(result, _undefined)
          ? this.result
          : result as EcourtsCase?,
      queryCnr: queryCnr ?? this.queryCnr,
      causeList: causeList ?? this.causeList,
      causeListLoading: causeListLoading ?? this.causeListLoading,
      recent: recent ?? this.recent,
      message: identical(message, _undefined) ? this.message : message as String?,
      searchCriteria: searchCriteria ?? this.searchCriteria,
      searchPhase: searchPhase ?? this.searchPhase,
      searchHits: searchHits ?? this.searchHits,
      searchError: searchError ?? this.searchError,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

const Object _undefined = Object();
