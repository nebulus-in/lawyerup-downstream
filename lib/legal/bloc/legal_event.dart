part of 'legal_bloc.dart';

abstract class LegalEvent extends Equatable {
  const LegalEvent();
  @override
  List<Object?> get props => [];
}

class LoadCases extends LegalEvent {}

class TabChanged extends LegalEvent {
  final String tab;
  const TabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

class CaseSelected extends LegalEvent {
  final int? caseId;
  const CaseSelected(this.caseId);
  @override
  List<Object?> get props => [caseId];
}

class CategorySelected extends LegalEvent {
  final int? categoryId;
  const CategorySelected(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class DateSelected extends LegalEvent {
  final DateTime? date;
  const DateSelected(this.date);
  @override
  List<Object?> get props => [date];
}

class CaseCreated extends LegalEvent {
  final String name;
  final String number;
  final String court;
  final String type;
  final List<String> folders;

  const CaseCreated({
    required this.name,
    required this.number,
    required this.court,
    required this.type,
    this.folders = const [],
  });
  @override
  List<Object?> get props => [name, number, court, type, folders];
}

class CaseUpdated extends LegalEvent {
  final int caseId;
  final String name;
  final String number;
  final String court;
  final String type;
  final String hearing;
  const CaseUpdated({
    required this.caseId,
    required this.name,
    required this.number,
    required this.court,
    required this.type,
    required this.hearing,
  });
  @override
  List<Object?> get props => [caseId, name, number, court, type, hearing];
}

class CaseScheduled extends LegalEvent {
  final int caseId;
  final String hearing;
  const CaseScheduled(this.caseId, this.hearing);
  @override
  List<Object?> get props => [caseId, hearing];
}

class CategoryAdded extends LegalEvent {
  final int caseId;
  final String name;
  const CategoryAdded(this.caseId, this.name);
  @override
  List<Object?> get props => [caseId, name];
}

class FileUploaded extends LegalEvent {
  final int caseId;
  final String? categoryName;
  const FileUploaded(this.caseId, this.categoryName);
  @override
  List<Object?> get props => [caseId, categoryName];
}

class DocumentScanned extends LegalEvent {
  final int caseId;
  final String? categoryName;
  final ScannedDocument document;
  const DocumentScanned(this.caseId, this.categoryName, this.document);
  @override
  List<Object?> get props => [caseId, categoryName, document.path];
}
