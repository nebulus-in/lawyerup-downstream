import 'package:equatable/equatable.dart';
import '../../../services/ecourts/ecourts_models.dart';

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

class EcourtsCauseEntryOpened extends EcourtsEvent {
  final CauseListEntry entry;

  const EcourtsCauseEntryOpened(this.entry);

  @override
  List<Object?> get props => [entry];
}

class EcourtsResetRequested extends EcourtsEvent {
  const EcourtsResetRequested();
}
