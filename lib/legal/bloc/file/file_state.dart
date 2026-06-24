part of 'file_bloc.dart';

/// Whether a file operation (upload, delete, move, …) is currently running.
enum FileStatus { idle, inProgress }

/// State for file operations and multi-select mode.
class FileState extends Equatable {
  /// IDs of files currently selected for batch actions (e.g. moving).
  final Set<int> selectedFileIds;

  /// Whether a file operation is currently running.
  final FileStatus status;

  /// The case ID receiving an upload, if [status] is [FileStatus.inProgress].
  final int? uploadingToCaseId;

  /// The folder name receiving an upload, if [status] is [FileStatus.inProgress].
  final String? uploadingToCategoryName;

  /// The name of the file being uploaded, if known.
  final String? uploadingFileName;

  /// Transient error message for the UI to surface (e.g. a SnackBar).
  final String? errorMessage;

  const FileState({
    this.selectedFileIds = const {},
    this.status = FileStatus.idle,
    this.uploadingToCaseId,
    this.uploadingToCategoryName,
    this.uploadingFileName,
    this.errorMessage,
  });

  bool get isMultiSelectMode => selectedFileIds.isNotEmpty;
  bool get isProcessing => status == FileStatus.inProgress;

  @override
  List<Object?> get props => [
        selectedFileIds,
        status,
        uploadingToCaseId,
        uploadingToCategoryName,
        uploadingFileName,
        errorMessage,
      ];

  FileState copyWith({
    Set<int>? selectedFileIds,
    FileStatus? status,
    int? uploadingToCaseId,
    String? uploadingToCategoryName,
    String? uploadingFileName,
    String? errorMessage,
  }) {
    return FileState(
      selectedFileIds: selectedFileIds ?? this.selectedFileIds,
      status: status ?? this.status,
      uploadingToCaseId: uploadingToCaseId ?? this.uploadingToCaseId,
      uploadingToCategoryName:
          uploadingToCategoryName ?? this.uploadingToCategoryName,
      uploadingFileName: uploadingFileName ?? this.uploadingFileName,
      errorMessage: errorMessage,
    );
  }
}
