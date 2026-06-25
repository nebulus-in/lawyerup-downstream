import 'package:equatable/equatable.dart';

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
