import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../repositories/legal_repository.dart';
import '../../../services/docx_to_pdf_service.dart';
import '../../../services/document_scanner_service.dart';
import '../../../services/download_service.dart';

part 'file_event.dart';
part 'file_state.dart';

/// Manages file operations and multi-select state.
/// Handles uploading, scanning, moving, deleting, and renaming files.
///
/// Mutations use a [droppable] transformer so a rapid double-tap (e.g. two
/// "Delete" taps) is ignored while the first is still in flight. Selection
/// toggles keep the default transformer so none are lost.
class FileBloc extends Bloc<FileEvent, FileState> {
  final LegalRepository _repository;

  FileBloc({required LegalRepository repository})
      : _repository = repository,
        super(const FileState()) {
    on<SelectionToggled>(_onSelectionToggled);
    on<SelectionCleared>(_onSelectionCleared);
    on<FileUploaded>(_onFileUploaded, transformer: droppable());
    on<DocumentScanned>(_onDocumentScanned, transformer: droppable());
    on<FileDownloaded>(_onFileDownloaded, transformer: droppable());
    on<OcrTextSaved>(_onOcrTextSaved, transformer: droppable());
    on<PdfConversionSaved>(_onPdfConversionSaved, transformer: droppable());
    on<FileRenamed>(_onFileRenamed, transformer: droppable());
    on<FileDeleted>(_onFileDeleted, transformer: droppable());
    on<FilesDeleted>(_onFilesDeleted, transformer: droppable());
    on<FileMoved>(_onFileMoved, transformer: droppable());
    on<FilesMoved>(_onFilesMoved, transformer: droppable());
  }

  void _onSelectionToggled(SelectionToggled event, Emitter<FileState> emit) {
    final updated = Set<int>.from(state.selectedFileIds);
    if (updated.contains(event.id)) {
      updated.remove(event.id);
    } else {
      updated.add(event.id);
    }
    emit(state.copyWith(selectedFileIds: updated));
  }

  void _onSelectionCleared(SelectionCleared event, Emitter<FileState> emit) {
    emit(state.copyWith(selectedFileIds: {}));
  }

  Future<void> _onFileUploaded(FileUploaded event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not upload the file. Please try again.',
          () => _repository.uploadFile(
                event.caseId,
                event.categoryName,
                name: event.name,
                size: event.size,
                path: event.path,
              ),
          uploadingToCaseId: event.caseId,
          uploadingToCategoryName: event.categoryName,
          uploadingFileName: event.name);

  Future<void> _onDocumentScanned(
          DocumentScanned event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not save the scanned document. Please try again.',
          () => _repository.addScannedDocument(
              event.caseId, event.categoryName, event.document),
          uploadingToCaseId: event.caseId,
          uploadingToCategoryName: event.categoryName,
          uploadingFileName: event.document.fileName);

  Future<void> _onFileDownloaded(
          FileDownloaded event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not save the download. Please try again.',
          () => _repository.addDownloadedFile(
              event.caseId, event.categoryName, event.document),
          uploadingToCaseId: event.caseId,
          uploadingToCategoryName: event.categoryName,
          uploadingFileName: event.document.fileName);

  Future<void> _onOcrTextSaved(OcrTextSaved event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not save OCR text. Please try again.',
          () => _repository.saveOcrText(
                caseId: event.caseId,
                categoryName: event.categoryName,
                text: event.text,
                fileName: event.fileName,
              ),
          uploadingToCaseId: event.caseId,
          uploadingToCategoryName: event.categoryName,
          uploadingFileName: event.fileName);

  Future<void> _onPdfConversionSaved(PdfConversionSaved event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not save PDF conversion. Please try again.',
          () => _repository.savePdfConversion(
              event.caseId, event.categoryName, event.document),
          uploadingToCaseId: event.caseId,
          uploadingToCategoryName: event.categoryName,
          uploadingFileName: event.document.fileName);

  Future<void> _onFileRenamed(FileRenamed event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not rename the file. Please try again.',
          () =>
              _repository.renameFile(event.caseId, event.fileId, event.newName));

  Future<void> _onFileDeleted(FileDeleted event, Emitter<FileState> emit) =>
      _runMutation(emit, 'Could not delete the file. Please try again.',
          () => _repository.deleteFile(event.caseId, event.fileId));

  Future<void> _onFilesDeleted(FilesDeleted event, Emitter<FileState> emit) =>
      _runMutation(emit, 'Could not delete the files. Please try again.',
          () => _repository.deleteFiles(event.caseId, event.fileIds),
          clearSelection: true);

  Future<void> _onFileMoved(FileMoved event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not move the file. Please try again.',
          () => _repository.moveFile(
              event.caseId, event.fileId, event.targetCategoryName));

  Future<void> _onFilesMoved(FilesMoved event, Emitter<FileState> emit) =>
      _runMutation(
          emit,
          'Could not move the files. Please try again.',
          () => _repository.moveFiles(
              event.caseId, event.fileIds, event.targetCategoryName),
          clearSelection: true);

  /// Runs a mutation with the shared in-flight envelope: flips [status] to
  /// `inProgress`, runs [op], returns to `idle` (clearing the selection when
  /// [clearSelection] is set), and surfaces [failMessage] on error. The updated
  /// case list flows back to [CaseBloc] through the repository stream.
  Future<void> _runMutation(
    Emitter<FileState> emit,
    String failMessage,
    Future<void> Function() op, {
    bool clearSelection = false,
    int? uploadingToCaseId,
    String? uploadingToCategoryName,
    String? uploadingFileName,
  }) async {
    emit(state.copyWith(
      status: FileStatus.inProgress,
      uploadingToCaseId: uploadingToCaseId,
      uploadingToCategoryName: uploadingToCategoryName,
      uploadingFileName: uploadingFileName,
    ));
    try {
      await op();
      emit(state.copyWith(
        status: FileStatus.idle,
        selectedFileIds: clearSelection ? <int>{} : null,
        uploadingToCaseId: null,
        uploadingToCategoryName: null,
        uploadingFileName: null,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: FileStatus.idle,
        errorMessage: failMessage,
        uploadingToCaseId: null,
        uploadingToCategoryName: null,
        uploadingFileName: null,
      ));
    }
  }
}
