part of 'file_bloc.dart';

/// Whether a file operation (upload, delete, move, …) is currently running.
///
/// Note: with the in-memory repository, mutations resolve near-instantly, so
/// [inProgress] is effectively momentary today. It exists so the UI can show a
/// spinner / disable controls once the repository performs real async I/O.
enum FileStatus { idle, inProgress }

/// State for file operations and multi-select mode. Holds selection, the
/// in-flight [status], and a transient error message only — the canonical case
/// list lives in [CaseBloc], fed by the repository stream. Success feedback is
/// surfaced optimistically at the call sites (see the view layer).
class FileState extends Equatable {
  /// IDs of files currently selected for batch actions (e.g. moving).
  final Set<int> selectedFileIds;

  /// Whether a file operation is currently running.
  final FileStatus status;

  /// Transient error message for the UI to surface (e.g. a SnackBar).
  /// Unlike [status] and [selectedFileIds] it is *not* preserved across
  /// [copyWith] calls — it is a one-shot signal.
  final String? errorMessage;

  const FileState({
    this.selectedFileIds = const {},
    this.status = FileStatus.idle,
    this.errorMessage,
  });

  bool get isMultiSelectMode => selectedFileIds.isNotEmpty;
  bool get isProcessing => status == FileStatus.inProgress;

  @override
  List<Object?> get props => [
        selectedFileIds,
        status,
        errorMessage,
      ];

  FileState copyWith({
    Set<int>? selectedFileIds,
    FileStatus? status,
    String? errorMessage,
  }) {
    return FileState(
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
