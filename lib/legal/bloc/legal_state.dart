part of 'legal_bloc.dart';

const Object _undefined = Object();

class LegalState extends Equatable {
  final String activeTab;
  final int? selectedCaseId;
  final int? selectedCategoryId;
  final String? selectedDate;
  final List<Case> cases;

  const LegalState({
    this.activeTab = 'documents',
    this.selectedCaseId,
    this.selectedCategoryId,
    this.selectedDate,
    this.cases = const [],
  });

  @override
  List<Object?> get props => [
        activeTab,
        selectedCaseId,
        selectedCategoryId,
        selectedDate,
        cases,
      ];

  LegalState copyWith({
    String? activeTab,
    Object? selectedCaseId = _undefined,
    Object? selectedCategoryId = _undefined,
    Object? selectedDate = _undefined,
    List<Case>? cases,
  }) {
    return LegalState(
      activeTab: activeTab ?? this.activeTab,
      selectedCaseId: identical(selectedCaseId, _undefined)
          ? this.selectedCaseId
          : selectedCaseId as int?,
      selectedCategoryId: identical(selectedCategoryId, _undefined)
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      selectedDate: identical(selectedDate, _undefined)
          ? this.selectedDate
          : selectedDate as String?,
      cases: cases ?? this.cases,
    );
  }
}
