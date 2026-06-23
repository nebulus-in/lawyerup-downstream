import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

/// Manages navigation state and tab switching within the legal app.
/// Handles UI navigation concerns like active tab, selected items, and modals.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<TabChanged>(_onTabChanged);
    on<CaseSelected>(_onCaseSelected);
    on<CategorySelected>(_onCategorySelected);
    on<DateSelected>(_onDateSelected);
    on<LongPressedIdChanged>(_onLongPressedIdChanged);
  }

  void _onTabChanged(TabChanged event, Emitter<NavigationState> emit) {
    final isSameTab = event.tab == state.activeTab;
    emit(state.copyWith(
      activeTab: event.tab,
      // Keep the existing previous tab when re-selecting the current tab.
      previousTab: isSameTab ? null : state.activeTab,
      selectedCaseId: null,
      selectedCategoryId: null,
      selectedDate: null,
      longPressedId: null,
    ));
  }

  void _onCaseSelected(CaseSelected event, Emitter<NavigationState> emit) {
    emit(state.copyWith(
      selectedCaseId: event.caseId,
      selectedCategoryId: null,
      longPressedId: null,
    ));
  }

  void _onCategorySelected(CategorySelected event, Emitter<NavigationState> emit) {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      longPressedId: null,
    ));
  }

  void _onDateSelected(DateSelected event, Emitter<NavigationState> emit) {
    emit(state.copyWith(selectedDate: event.date));
  }

  void _onLongPressedIdChanged(
      LongPressedIdChanged event, Emitter<NavigationState> emit) {
    emit(state.copyWith(longPressedId: event.id));
  }
}
