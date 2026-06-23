import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../repositories/legal_repository.dart';

part 'category_event.dart';
part 'category_state.dart';

/// Manages category (folder) operations within cases.
/// Handles CRUD operations for organizing case documents.
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final LegalRepository _repository;

  CategoryBloc({required LegalRepository repository})
      : _repository = repository,
        super(const CategoryState()) {
    on<CategoryAdded>(_onCategoryAdded);
    on<CategoryRenamed>(_onCategoryRenamed);
    on<CategoryDeleted>(_onCategoryDeleted);
  }

  Future<void> _onCategoryAdded(
      CategoryAdded event, Emitter<CategoryState> emit) async {
    try {
      await _repository.addCategory(event.caseId, event.name);
      emit(state.copyWith(successMessage: 'Folder created successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not add the folder. Please try again.'));
    }
  }

  Future<void> _onCategoryRenamed(
      CategoryRenamed event, Emitter<CategoryState> emit) async {
    try {
      await _repository.renameCategory(
          event.caseId, event.categoryId, event.newName);
      emit(state.copyWith(successMessage: 'Folder renamed successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not rename the folder. Please try again.'));
    }
  }

  Future<void> _onCategoryDeleted(
      CategoryDeleted event, Emitter<CategoryState> emit) async {
    try {
      await _repository.deleteCategory(event.caseId, event.categoryId);
      emit(state.copyWith(successMessage: 'Folder deleted successfully.'));
    } catch (e) {
      emit(state.copyWith(
          errorMessage: 'Could not delete the folder. Please try again.'));
    }
  }
}
