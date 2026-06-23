part of 'category_bloc.dart';

/// State for category operations. Holds only transient UI messages — the
/// canonical case list lives in [CaseBloc], fed by the repository stream.
class CategoryState extends Equatable {
  /// Transient error message for the UI to surface (e.g. a SnackBar).
  final String? errorMessage;

  /// Transient success message for the UI to surface.
  final String? successMessage;

  const CategoryState({
    this.errorMessage,
    this.successMessage,
  });

  @override
  List<Object?> get props => [errorMessage, successMessage];

  CategoryState copyWith({
    String? errorMessage,
    String? successMessage,
  }) {
    return CategoryState(
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
