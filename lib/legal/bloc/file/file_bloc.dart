import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../repositories/legal_repository.dart';
import '../../../services/document_scanner_service.dart';

part 'file_event.dart';
part 'file_state.dart';

/// Manages file operations and multi-select state.
/// Handles uploading, scanning, moving, deleting, and renaming files.
class FileBloc extends Bloc<FileEvent, FileState> {
  final LegalRepository _repository;

  FileBloc({required LegalRepository repository})
      : _repository = repository,
        super(const FileState()) {
    on<SelectionToggled>(_onSelectionToggled);
    on<SelectionCleared>(_onSelectionCleared);
    on<FileUploaded>(_onFileUploaded);
    on<DocumentScanned>(_onDocumentScanned);
    on<OcrTextSaved>(_onOcrTextSaved);
    on<FileRenamed>(_onFileRenamed);
    on<FileDeleted>(_onFileDeleted);
    on<FilesDeleted>(_onFilesDeleted);
    on<FileMoved>(_onFileMoved);
    on<FilesMoved>(_onFilesMoved);
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

  Future<void> _onFileUploaded(
      FileUploaded event, Emitter<FileState> emit) async {
    try {
      await _repository.uploadFile(event.caseId, event.categoryName);
      emit(state.copyWith(successMessage: 'File uploaded successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not upload the file. Please try again.'));
    }
  }

  Future<void> _onDocumentScanned(
      DocumentScanned event, Emitter<FileState> emit) async {
    try {
      await _repository.addScannedDocument(
          event.caseId, event.categoryName, event.document);
      emit(state.copyWith(successMessage: 'Document scanned and saved.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage:
              'Could not save the scanned document. Please try again.'));
    }
  }

  Future<void> _onOcrTextSaved(
      OcrTextSaved event, Emitter<FileState> emit) async {
    try {
      await _repository.saveOcrText(
        caseId: event.caseId,
        categoryName: event.categoryName,
        text: event.text,
        fileName: event.fileName,
      );
      emit(state.copyWith(successMessage: 'OCR text saved successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not save OCR text. Please try again.'));
    }
  }

  Future<void> _onFileRenamed(FileRenamed event, Emitter<FileState> emit) async {
    try {
      await _repository.renameFile(event.caseId, event.fileId, event.newName);
      emit(state.copyWith(successMessage: 'File renamed successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not rename the file. Please try again.'));
    }
  }

  Future<void> _onFileDeleted(FileDeleted event, Emitter<FileState> emit) async {
    try {
      await _repository.deleteFile(event.caseId, event.fileId);
      emit(state.copyWith(successMessage: 'File deleted successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not delete the file. Please try again.'));
    }
  }

  Future<void> _onFilesDeleted(
      FilesDeleted event, Emitter<FileState> emit) async {
    try {
      await _repository.deleteFiles(event.caseId, event.fileIds);
      emit(state.copyWith(
        selectedFileIds: {},
        successMessage: 'Files deleted successfully.',
      ));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not delete the files. Please try again.'));
    }
  }

  Future<void> _onFileMoved(FileMoved event, Emitter<FileState> emit) async {
    try {
      await _repository.moveFile(
          event.caseId, event.fileId, event.targetCategoryName);
      emit(state.copyWith(successMessage: 'File moved successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not move the file. Please try again.'));
    }
  }

  Future<void> _onFilesMoved(FilesMoved event, Emitter<FileState> emit) async {
    try {
      await _repository.moveFiles(
          event.caseId, event.fileIds, event.targetCategoryName);
      emit(state.copyWith(
        selectedFileIds: {},
        successMessage: 'Files moved successfully.',
      ));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not move the files. Please try again.'));
    }
  }
}
