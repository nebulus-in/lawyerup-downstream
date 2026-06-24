part of 'navigation_bloc.dart';

const Object _undefined = Object();

/// State for navigation within the legal app UI.
class NavigationState extends Equatable {
  final String activeTab;

  /// The tab that was active before the current one, used to power the
  /// back button on standalone screens like Profile.
  final String previousTab;
  final int? selectedCaseId;
  final int? selectedCategoryId;
  final DateTime? selectedDate;

  /// The id of the research source currently open in the in-app browser, or
  /// null when the sources list is showing.
  final String? selectedSource;

  /// The ID of the item (Case, Category, or CaseFile) currently being acted
  /// upon (e.g. while an options modal is open). Used to show a selection border.
  final int? longPressedId;

  /// A CNR to auto-load when the eCourts screen opens. Consumed once by
  /// [ECourtsView] and then cleared via [PendingCnrSet(null)].
  final String? pendingCnr;

  const NavigationState({
    this.activeTab = 'documents',
    this.previousTab = 'documents',
    this.selectedCaseId,
    this.selectedCategoryId,
    this.selectedDate,
    this.selectedSource,
    this.longPressedId,
    this.pendingCnr,
  });

  @override
  List<Object?> get props => [
        activeTab,
        previousTab,
        selectedCaseId,
        selectedCategoryId,
        selectedDate,
        selectedSource,
        longPressedId,
        pendingCnr,
      ];

  NavigationState copyWith({
    String? activeTab,
    String? previousTab,
    Object? selectedCaseId = _undefined,
    Object? selectedCategoryId = _undefined,
    Object? selectedDate = _undefined,
    Object? selectedSource = _undefined,
    Object? longPressedId = _undefined,
    Object? pendingCnr = _undefined,
  }) {
    return NavigationState(
      activeTab: activeTab ?? this.activeTab,
      previousTab: previousTab ?? this.previousTab,
      selectedCaseId: identical(selectedCaseId, _undefined)
          ? this.selectedCaseId
          : selectedCaseId as int?,
      selectedCategoryId: identical(selectedCategoryId, _undefined)
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      selectedDate: identical(selectedDate, _undefined)
          ? this.selectedDate
          : selectedDate as DateTime?,
      selectedSource: identical(selectedSource, _undefined)
          ? this.selectedSource
          : selectedSource as String?,
      longPressedId: identical(longPressedId, _undefined)
          ? this.longPressedId
          : longPressedId as int?,
      pendingCnr: identical(pendingCnr, _undefined)
          ? this.pendingCnr
          : pendingCnr as String?,
    );
  }
}
