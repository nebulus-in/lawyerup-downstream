import 'package:equatable/equatable.dart';

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
