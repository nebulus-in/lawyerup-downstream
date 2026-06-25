part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
  @override
  List<Object?> get props => [];
}

class CategoryErrorDismissed extends CategoryEvent {}

class CategoryAdded extends CategoryEvent {
  final int caseId;
  final String name;

  const CategoryAdded(this.caseId, this.name);
  @override
  List<Object?> get props => [caseId, name];
}

class CategoryRenamed extends CategoryEvent {
  final int caseId;
  final int categoryId;
  final String newName;

  const CategoryRenamed(this.caseId, this.categoryId, this.newName);
  @override
  List<Object?> get props => [caseId, categoryId, newName];
}

class CategoryDeleted extends CategoryEvent {
  final int caseId;
  final int categoryId;

  const CategoryDeleted(this.caseId, this.categoryId);
  @override
  List<Object?> get props => [caseId, categoryId];
}
