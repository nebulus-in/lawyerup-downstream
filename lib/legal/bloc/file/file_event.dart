part of 'file_bloc.dart';

abstract class FileEvent extends Equatable {
  const FileEvent();
  @override
  List<Object?> get props => [];
}

class SelectionToggled extends FileEvent {
  final int id;
  const SelectionToggled(this.id);
  @override
  List<Object?> get props => [id];
}

class SelectionCleared extends FileEvent {}

class FileUploaded extends FileEvent {
  final int caseId;
  final String? categoryName;

  const FileUploaded(this.caseId, this.categoryName);
  @override
  List<Object?> get props => [caseId, categoryName];
}

class DocumentScanned extends FileEvent {
  final int caseId;
  final String? categoryName;
  final ScannedDocument document;

  const DocumentScanned(this.caseId, this.categoryName, this.document);
  @override
  List<Object?> get props => [caseId, categoryName, document];
}

class FileDownloaded extends FileEvent {
  final int caseId;
  final String? categoryName;
  final DownloadedFile document;

  const FileDownloaded(this.caseId, this.categoryName, this.document);

  @override
  List<Object?> get props => [caseId, categoryName, document];
}

class OcrTextSaved extends FileEvent {
  final int caseId;
  final String? categoryName;
  final String text;
  final String fileName;

  const OcrTextSaved({
    required this.caseId,
    this.categoryName,
    required this.text,
    required this.fileName,
  });

  @override
  List<Object?> get props => [caseId, categoryName, text, fileName];
}

class FileRenamed extends FileEvent {
  final int caseId;
  final int fileId;
  final String newName;

  const FileRenamed(this.caseId, this.fileId, this.newName);
  @override
  List<Object?> get props => [caseId, fileId, newName];
}

class FileDeleted extends FileEvent {
  final int caseId;
  final int fileId;

  const FileDeleted(this.caseId, this.fileId);
  @override
  List<Object?> get props => [caseId, fileId];
}

class FilesDeleted extends FileEvent {
  final int caseId;
  final List<int> fileIds;

  const FilesDeleted(this.caseId, this.fileIds);
  @override
  List<Object?> get props => [caseId, fileIds];
}

class FileMoved extends FileEvent {
  final int caseId;
  final int fileId;
  final String? targetCategoryName;

  const FileMoved(this.caseId, this.fileId, this.targetCategoryName);
  @override
  List<Object?> get props => [caseId, fileId, targetCategoryName];
}

class FilesMoved extends FileEvent {
  final int caseId;
  final List<int> fileIds;
  final String? targetCategoryName;

  const FilesMoved(this.caseId, this.fileIds, this.targetCategoryName);
  @override
  List<Object?> get props => [caseId, fileIds, targetCategoryName];
}
