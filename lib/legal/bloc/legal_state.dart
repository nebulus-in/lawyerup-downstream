part of 'legal_bloc.dart';

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
    int? selectedCaseId,
    int? selectedCategoryId,
    String? selectedDate,
    List<Case>? cases,
  }) {
    return LegalState(
      activeTab: activeTab ?? this.activeTab,
      selectedCaseId: selectedCaseId ?? this.selectedCaseId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedDate: selectedDate ?? this.selectedDate,
      cases: cases ?? this.cases,
    );
  }
}
