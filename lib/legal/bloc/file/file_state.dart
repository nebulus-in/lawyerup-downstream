part of 'file_bloc.dart';

/// State for file operations and multi-select mode. Holds selection and
/// transient UI messages only — the canonical case list lives in [CaseBloc],
/// fed by the repository stream.
class FileState extends Equatable {
  /// IDs of files currently selected for batch actions (e.g. moving).
  final Set<int> selectedFileIds;

  /// Transient error message for the UI to surface (e.g. a SnackBar).
  final String? errorMessage;

  /// Transient success message for the UI to surface.
  final String? successMessage;

  const FileState({
    this.selectedFileIds = const {},
    this.errorMessage,
    this.successMessage,
  });

  bool get isMultiSelectMode => selectedFileIds.isNotEmpty;

  @override
  List<Object?> get props => [
        selectedFileIds,
        errorMessage,
        successMessage,
      ];

  FileState copyWith({
    Set<int>? selectedFileIds,
    String? errorMessage,
    String? successMessage,
  }) {
    return FileState(
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
