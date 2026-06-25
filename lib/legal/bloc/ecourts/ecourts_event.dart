import 'package:equatable/equatable.dart';

import 'ecourts_state.dart';

abstract class EcourtsEvent extends Equatable {
  const EcourtsEvent();

  @override
  List<Object?> get props => [];
}

class EcourtsCauseListRequested extends EcourtsEvent {
  const EcourtsCauseListRequested();
}

class EcourtsLookupRequested extends EcourtsEvent {
  final String raw;

  const EcourtsLookupRequested(this.raw);

  @override
  List<Object?> get props => [raw];
}

class EcourtsResetRequested extends EcourtsEvent {
  const EcourtsResetRequested();
}

/// Run a search with the given [criteria] (scoped text, status, hearing range,
/// sort). Criteria with nothing to match on clears the search and restores the
/// board.
class EcourtsSearchSubmitted extends EcourtsEvent {
  final SearchCriteria criteria;

  const EcourtsSearchSubmitted(this.criteria);

  @override
  List<Object?> get props => [criteria];
}
