import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/ecourts/ecourts_api.dart';
import 'ecourts_event.dart';
import 'ecourts_state.dart';

class EcourtsBloc extends Bloc<EcourtsEvent, EcourtsState> {
  final EcourtsApi _api;

  EcourtsBloc(this._api) : super(const EcourtsState()) {
    on<EcourtsCauseListRequested>(_onCauseListRequested);
    on<EcourtsLookupRequested>(_onLookupRequested);
    on<EcourtsResetRequested>(_onResetRequested);

    add(const EcourtsCauseListRequested());
  }

  Future<void> _onCauseListRequested(
    EcourtsCauseListRequested event,
    Emitter<EcourtsState> emit,
  ) async {
    emit(state.copyWith(causeListLoading: true));
    try {
      final list = await _api.causeList(CauseListQuery(date: DateTime.now()));
      emit(state.copyWith(causeList: list, causeListLoading: false));
    } catch (_) {
      emit(state.copyWith(causeListLoading: false));
    }
  }

  Future<void> _onLookupRequested(
    EcourtsLookupRequested event,
    Emitter<EcourtsState> emit,
  ) async {
    final cnr = Cnr.normalize(event.raw);
    if (!Cnr.isValid(cnr)) {
      emit(state.copyWith(
        status: EcourtsStatus.invalid,
        queryCnr: cnr,
        result: null,
        message: 'A CNR is 16 letters and digits — check for a missing one.',
      ));
      return;
    }

    emit(state.copyWith(
        status: EcourtsStatus.loading, queryCnr: cnr, message: null));
    try {
      final result = await _api.caseByCnr(cnr);
      final recent = [
        cnr,
        ...state.recent.where((r) => r != cnr),
      ].take(4).toList();
      emit(state.copyWith(
          status: EcourtsStatus.success, result: result, recent: recent));
    } on InvalidCnrException catch (e) {
      emit(state.copyWith(
          status: EcourtsStatus.invalid, result: null, message: e.message));
    } on CaseNotFoundException {
      emit(state.copyWith(status: EcourtsStatus.notFound, result: null));
    } on EcourtsException catch (e) {
      emit(state.copyWith(
          status: EcourtsStatus.error, result: null, message: e.message));
    }
  }

  void _onResetRequested(
    EcourtsResetRequested event,
    Emitter<EcourtsState> emit,
  ) {
    emit(state.copyWith(
      status: EcourtsStatus.idle,
      result: null,
      queryCnr: '',
      message: null,
    ));
  }

  @override
  Future<void> close() {
    _api.dispose();
    return super.close();
  }
}
