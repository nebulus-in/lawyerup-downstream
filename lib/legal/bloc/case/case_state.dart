part of 'case_bloc.dart';

enum CaseStatus { initial, loading, success, failure }

/// State for case data and operations.
class CaseState extends Equatable {
  final CaseStatus status;
  final List<Case> cases;
  final List<Case> upcomingHearings;
  
  /// Transient, one-shot error message for the UI to surface (e.g. a SnackBar).
  /// Unlike the other fields it is *not* preserved across [copyWith] calls.
  final String? errorMessage;

  const CaseState({
    this.status = CaseStatus.initial,
    this.cases = const [],
    this.upcomingHearings = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        status,
        cases,
        upcomingHearings,
        errorMessage,
      ];

  CaseState copyWith({
    CaseStatus? status,
    List<Case>? cases,
    List<Case>? upcomingHearings,
    String? errorMessage,
  }) {
    return CaseState(
      status: status ?? this.status,
      cases: cases ?? this.cases,
      upcomingHearings: upcomingHearings ?? this.upcomingHearings,
      errorMessage: errorMessage,
    );
  }
}
