part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();
  @override
  List<Object?> get props => [];
}

class TabChanged extends NavigationEvent {
  final String tab;
  const TabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

class CaseSelected extends NavigationEvent {
  final int? caseId;
  const CaseSelected(this.caseId);
  @override
  List<Object?> get props => [caseId];
}

/// Opens (or, when null, closes) a research source in the in-app browser.
class SourceSelected extends NavigationEvent {
  final String? sourceId;
  const SourceSelected(this.sourceId);
  @override
  List<Object?> get props => [sourceId];
}

class CategorySelected extends NavigationEvent {
  final int? categoryId;
  const CategorySelected(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class DateSelected extends NavigationEvent {
  final DateTime? date;
  const DateSelected(this.date);
  @override
  List<Object?> get props => [date];
}

class LongPressedIdChanged extends NavigationEvent {
  final int? id;
  const LongPressedIdChanged(this.id);
  @override
  List<Object?> get props => [id];
}
