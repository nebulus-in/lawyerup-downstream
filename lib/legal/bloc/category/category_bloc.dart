import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../repositories/legal_repository.dart';

part 'category_event.dart';
part 'category_state.dart';

/// Manages category (folder) operations within cases.
/// Handles CRUD operations for organizing case documents.
///
/// All handlers use a [droppable] transformer so a rapid double-tap is ignored
/// while the first operation is still in flight. Success feedback is surfaced
/// optimistically at the call sites (see the view layer).
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final LegalRepository _repository;

  CategoryBloc({required LegalRepository repository})
      : _repository = repository,
        super(const CategoryState()) {
    on<CategoryErrorDismissed>(_onCategoryErrorDismissed);
    on<CategoryAdded>(_onCategoryAdded, transformer: droppable());
    on<CategoryRenamed>(_onCategoryRenamed, transformer: droppable());
    on<CategoryDeleted>(_onCategoryDeleted, transformer: droppable());
  }

  void _onCategoryErrorDismissed(
          CategoryErrorDismissed event, Emitter<CategoryState> emit) =>
      emit(state.copyWith(errorMessage: null));

  Future<void> _onCategoryAdded(
          CategoryAdded event, Emitter<CategoryState> emit) =>
      _guard(emit, 'Could not add the folder. Please try again.',
          () => _repository.addCategory(event.caseId, event.name));

  Future<void> _onCategoryRenamed(
          CategoryRenamed event, Emitter<CategoryState> emit) =>
      _guard(emit, 'Could not rename the folder. Please try again.',
          () => _repository.renameCategory(
              event.caseId, event.categoryId, event.newName));

  Future<void> _onCategoryDeleted(
          CategoryDeleted event, Emitter<CategoryState> emit) =>
      _guard(emit, 'Could not delete the folder. Please try again.',
          () => _repository.deleteCategory(event.caseId, event.categoryId));

  /// Runs [op], surfacing [failMessage] as a transient error if it throws.
  /// Success needs no state of its own — the updated case list flows back to
  /// [CaseBloc] through the repository stream.
  Future<void> _guard(Emitter<CategoryState> emit, String failMessage,
      Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      emit(state.copyWith(errorMessage: failMessage));
    }
  }
}
