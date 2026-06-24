import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/ecourts/ecourts_api.dart';
import '../../../services/ecourts/ecourts_models.dart';

/// Where a CNR lookup currently stands.
enum EcourtsStatus { idle, loading, success, notFound, invalid, error }

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

  const EcourtsState({
    this.status = EcourtsStatus.idle,
    this.result,
    this.queryCnr = '',
    this.causeList = const [],
    this.causeListLoading = false,
    this.recent = const [],
    this.message,
  });

  @override
  List<Object?> get props =>
      [status, result, queryCnr, causeList, causeListLoading, recent, message];

  EcourtsState copyWith({
    EcourtsStatus? status,
    Object? result = _undefined,
    String? queryCnr,
    List<CauseListEntry>? causeList,
    bool? causeListLoading,
    List<String>? recent,
    Object? message = _undefined,
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
    );
  }
}

const Object _undefined = Object();

/// Orchestrates lookups against an [EcourtsApi]. Validation happens here so the
/// UI can react instantly to a malformed CNR without a round-trip, while the
/// real not-found/error cases come back from the API.
class EcourtsCubit extends Cubit<EcourtsState> {
  final EcourtsApi _api;

  EcourtsCubit(this._api) : super(const EcourtsState()) {
    _loadCauseList();
  }

  Future<void> _loadCauseList() async {
    emit(state.copyWith(causeListLoading: true));
    try {
      final list = await _api.causeList(CauseListQuery(date: DateTime.now()));
      emit(state.copyWith(causeList: list, causeListLoading: false));
    } catch (_) {
      emit(state.copyWith(causeListLoading: false));
    }
  }

  /// Looks up [raw] by CNR. Rejects malformed input locally, then maps the
  /// API's exceptions onto the screen's states.
  Future<void> lookup(String raw) async {
    final cnr = Cnr.normalize(raw);
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

  /// Returns to the idle screen, clearing the current result.
  void reset() => emit(state.copyWith(
        status: EcourtsStatus.idle,
        result: null,
        queryCnr: '',
        message: null,
      ));
}
