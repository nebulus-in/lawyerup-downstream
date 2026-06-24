part of 'category_bloc.dart';

/// State for category operations. Holds only a transient error message — the
/// canonical case list lives in [CaseBloc], fed by the repository stream, and
/// success feedback is surfaced optimistically at the call sites.
class CategoryState extends Equatable {
  /// Transient error message for the UI to surface (e.g. a SnackBar).
  final String? errorMessage;

  const CategoryState({
    this.errorMessage,
  });

  @override
  List<Object?> get props => [errorMessage];

  CategoryState copyWith({
    String? errorMessage,
  }) {
    return CategoryState(
      errorMessage: errorMessage,
    );
  }
}
