part of 'legal_bloc.dart';

const Object _undefined = Object();

enum LegalStatus { initial, loading, success, failure }

class LegalState extends Equatable {
  final LegalStatus status;
  final String activeTab;
  final int? selectedCaseId;
  final int? selectedCategoryId;
  final DateTime? selectedDate;
  final List<Case> cases;
  final List<Case> upcomingHearings;
  
  /// The ID of the item (Case, Category, or CaseFile) currently being acted 
  /// upon (e.g. while an options modal is open). Used to show a selection border.
  final int? longPressedId;

  /// Transient, one-shot error message for the UI to surface (e.g. a SnackBar).
  /// Unlike the other fields it is *not* preserved across [copyWith] calls — it
  /// defaults back to null on the next emit so the same error can't linger or
  /// re-fire. See [copyWith].
  final String? errorMessage;

  const LegalState({
    this.status = LegalStatus.initial,
    this.activeTab = 'documents',
    this.selectedCaseId,
    this.selectedCategoryId,
    this.selectedDate,
    this.cases = const [],
    this.upcomingHearings = const [],
    this.longPressedId,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        status,
        activeTab,
        selectedCaseId,
        selectedCategoryId,
        selectedDate,
        cases,
        upcomingHearings,
        longPressedId,
        errorMessage,
      ];

  LegalState copyWith({
    LegalStatus? status,
    String? activeTab,
    Object? selectedCaseId = _undefined,
    Object? selectedCategoryId = _undefined,
    Object? selectedDate = _undefined,
    List<Case>? cases,
    List<Case>? upcomingHearings,
    Object? longPressedId = _undefined,
    // Transient: intentionally *not* preserved. Any copyWith that doesn't pass
    // it clears the message, so it only lives for the single emit that sets it.
    String? errorMessage,
  }) {
    return LegalState(
      status: status ?? this.status,
      activeTab: activeTab ?? this.activeTab,
      selectedCaseId: identical(selectedCaseId, _undefined)
          ? this.selectedCaseId
          : selectedCaseId as int?,
      selectedCategoryId: identical(selectedCategoryId, _undefined)
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      selectedDate: identical(selectedDate, _undefined)
          ? this.selectedDate
          : selectedDate as DateTime?,
      cases: cases ?? this.cases,
      upcomingHearings: upcomingHearings ?? this.upcomingHearings,
      longPressedId: identical(longPressedId, _undefined)
          ? this.longPressedId
          : longPressedId as int?,
      errorMessage: errorMessage,
    );
  }
}
