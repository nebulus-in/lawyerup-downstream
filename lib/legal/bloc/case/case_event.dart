part of 'case_bloc.dart';

abstract class CaseEvent extends Equatable {
  const CaseEvent();
  @override
  List<Object?> get props => [];
}

class LoadCases extends CaseEvent {}

/// Internal event fired when the repository broadcasts a new case list.
/// Keeps [CaseBloc] in sync with mutations made through any other BLoC.
class _CasesUpdated extends CaseEvent {
  final List<Case> cases;
  const _CasesUpdated(this.cases);
  @override
  List<Object?> get props => [cases];
}

class CaseCreated extends CaseEvent {
  final String name;
  final String number;
  final String court;
  final String type;
  final List<String> folders;
  final String? cnr;
  final String? hearing;

  const CaseCreated({
    required this.name,
    required this.number,
    required this.court,
    required this.type,
    required this.folders,
    this.cnr,
    this.hearing,
  });

  @override
  List<Object?> get props => [name, number, court, type, folders, cnr, hearing];
}

class CaseUpdated extends CaseEvent {
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

class CaseDeleted extends CaseEvent {
  final int caseId;
  const CaseDeleted(this.caseId);
  @override
  List<Object?> get props => [caseId];
}

class CaseScheduled extends CaseEvent {
  final int caseId;
  final String hearing;

  const CaseScheduled(this.caseId, this.hearing);
  @override
  List<Object?> get props => [caseId, hearing];
}
