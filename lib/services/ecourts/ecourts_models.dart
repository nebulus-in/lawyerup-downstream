import 'package:equatable/equatable.dart';

/// Typed models mirroring the JSON the eCourts India case-data API returns
/// (the "Partner API" documented at ecourtsindia.com/api/docs).
///
/// They are deliberately separate from the app's own [Case] model: this is a
/// faithful shape of the *external* service. A real HTTP client can map a
/// decoded JSON body straight onto these types through the [fromJson]
/// factories, and the app maps from here into its own domain where it needs to.
/// The bundled `MockEcourtsApi` returns these same types, so swapping the mock
/// for a live client touches nothing above the service layer.

/// Parses an ISO `yyyy-MM-dd` (or full ISO-8601) date, tolerating null/empty.
DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString().trim();
  return s.isEmpty ? null : DateTime.tryParse(s);
}

String _str(dynamic v) => v?.toString() ?? '';

List<Map<String, dynamic>> _objList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

/// A party to a case (petitioner or respondent) and the advocate on record.
class EcourtsParty extends Equatable {
  final String name;
  final String? advocate;

  const EcourtsParty({required this.name, this.advocate});

  factory EcourtsParty.fromJson(Map<String, dynamic> json) => EcourtsParty(
        name: _str(json['name']),
        advocate:
            json['advocate'] == null ? null : _str(json['advocate']),
      );

  @override
  List<Object?> get props => [name, advocate];
}

/// An act-and-section the case is registered under (e.g. IPC, s. 420).
class EcourtsAct extends Equatable {
  final String act;
  final String section;

  const EcourtsAct({required this.act, required this.section});

  factory EcourtsAct.fromJson(Map<String, dynamic> json) => EcourtsAct(
        act: _str(json['act']),
        section: _str(json['section']),
      );

  @override
  List<Object?> get props => [act, section];
}

/// One row of the case's hearing history: what happened on [businessOnDate],
/// what it was listed for, and the [nextDate] it was adjourned to.
class EcourtsHearing extends Equatable {
  final DateTime? businessOnDate;
  final DateTime? nextDate;
  final String purpose;
  final String judge;

  const EcourtsHearing({
    this.businessOnDate,
    this.nextDate,
    required this.purpose,
    required this.judge,
  });

  factory EcourtsHearing.fromJson(Map<String, dynamic> json) => EcourtsHearing(
        businessOnDate: _date(json['businessOnDate']),
        nextDate: _date(json['nextDate']),
        purpose: _str(json['purpose']),
        judge: _str(json['judge']),
      );

  @override
  List<Object?> get props => [businessOnDate, nextDate, purpose, judge];
}

/// A final or interim order/judgment, with the link to its PDF on the portal.
class EcourtsOrder extends Equatable {
  final int number;
  final String name;
  final DateTime? date;
  final String url;

  const EcourtsOrder({
    required this.number,
    required this.name,
    this.date,
    required this.url,
  });

  factory EcourtsOrder.fromJson(Map<String, dynamic> json) => EcourtsOrder(
        number: (json['number'] as num?)?.toInt() ?? 0,
        name: _str(json['name']),
        date: _date(json['date']),
        url: _str(json['url']),
      );

  @override
  List<Object?> get props => [number, name, date, url];
}

/// First-information-report details, present only on criminal matters.
class EcourtsFir extends Equatable {
  final String policeStation;
  final String firNumber;
  final String year;

  const EcourtsFir({
    required this.policeStation,
    required this.firNumber,
    required this.year,
  });

  factory EcourtsFir.fromJson(Map<String, dynamic> json) => EcourtsFir(
        policeStation: _str(json['policeStation']),
        firNumber: _str(json['firNumber']),
        year: _str(json['year']),
      );

  @override
  List<Object?> get props => [policeStation, firNumber, year];
}

/// The live status block: where the case stands and when it is next listed.
class EcourtsCaseStatus extends Equatable {
  /// Free-text stage, e.g. "Arguments", "Evidence", "Disposed".
  final String stage;

  /// Coarse state from the API's enumeration, e.g. "Pending" or "Disposed".
  final String caseStatus;

  final DateTime? firstHearingDate;
  final DateTime? nextHearingDate;
  final DateTime? decisionDate;
  final String? natureOfDisposal;
  final String courtNumberAndJudge;

  const EcourtsCaseStatus({
    required this.stage,
    required this.caseStatus,
    this.firstHearingDate,
    this.nextHearingDate,
    this.decisionDate,
    this.natureOfDisposal,
    required this.courtNumberAndJudge,
  });

  factory EcourtsCaseStatus.fromJson(Map<String, dynamic> json) =>
      EcourtsCaseStatus(
        stage: _str(json['stage']),
        caseStatus: _str(json['caseStatus']),
        firstHearingDate: _date(json['firstHearingDate']),
        nextHearingDate: _date(json['nextHearingDate']),
        decisionDate: _date(json['decisionDate']),
        natureOfDisposal: json['natureOfDisposal'] == null
            ? null
            : _str(json['natureOfDisposal']),
        courtNumberAndJudge: _str(json['courtNumberAndJudge']),
      );

  @override
  List<Object?> get props => [
        stage,
        caseStatus,
        firstHearingDate,
        nextHearingDate,
        decisionDate,
        natureOfDisposal,
        courtNumberAndJudge,
      ];
}

/// A complete case record keyed by its 16-character CNR — the response of the
/// "case by CNR" endpoint.
class EcourtsCase extends Equatable {
  final String cnr;
  final String caseType;
  final String filingNumber;
  final DateTime? filingDate;
  final String registrationNumber;
  final DateTime? registrationDate;
  final EcourtsCaseStatus status;
  final List<EcourtsParty> petitioners;
  final List<EcourtsParty> respondents;
  final List<EcourtsAct> acts;
  final List<EcourtsHearing> history;
  final List<EcourtsOrder> orders;
  final EcourtsFir? fir;

  /// Where the record was scraped from (the court establishment name).
  final String source;

  /// When the partner API last refreshed this record from the portal.
  final DateTime fetchedAt;

  const EcourtsCase({
    required this.cnr,
    required this.caseType,
    required this.filingNumber,
    this.filingDate,
    required this.registrationNumber,
    this.registrationDate,
    required this.status,
    this.petitioners = const [],
    this.respondents = const [],
    this.acts = const [],
    this.history = const [],
    this.orders = const [],
    this.fir,
    required this.source,
    required this.fetchedAt,
  });

  factory EcourtsCase.fromJson(Map<String, dynamic> json) => EcourtsCase(
        cnr: _str(json['cnr']),
        caseType: _str(json['caseType']),
        filingNumber: _str(json['filingNumber']),
        filingDate: _date(json['filingDate']),
        registrationNumber: _str(json['registrationNumber']),
        registrationDate: _date(json['registrationDate']),
        status: EcourtsCaseStatus.fromJson(
            (json['status'] as Map?)?.cast<String, dynamic>() ?? const {}),
        petitioners:
            _objList(json['petitioners']).map(EcourtsParty.fromJson).toList(),
        respondents:
            _objList(json['respondents']).map(EcourtsParty.fromJson).toList(),
        acts: _objList(json['acts']).map(EcourtsAct.fromJson).toList(),
        history:
            _objList(json['history']).map(EcourtsHearing.fromJson).toList(),
        orders: _objList(json['orders']).map(EcourtsOrder.fromJson).toList(),
        fir: json['fir'] == null
            ? null
            : EcourtsFir.fromJson((json['fir'] as Map).cast<String, dynamic>()),
        source: _str(json['source']),
        fetchedAt: _date(json['fetchedAt']) ?? DateTime.now(),
      );

  String get petitionerName =>
      petitioners.isEmpty ? 'Unknown' : petitioners.first.name;
  String get respondentName =>
      respondents.isEmpty ? 'Unknown' : respondents.first.name;

  /// Cause-title shorthand, e.g. "Smith vs Johnson".
  String get title => '$petitionerName vs $respondentName';

  bool get isDisposed =>
      status.decisionDate != null ||
      status.caseStatus.toLowerCase().contains('dispos');

  DateTime? get nextHearingDate => status.nextHearingDate;

  @override
  List<Object?> get props => [cnr, caseType, filingNumber, fetchedAt];
}

/// One line of a daily cause list — the schedule of matters before a court.
class CauseListEntry extends Equatable {
  final int serial;
  final String cnr;
  final String caseNumber;
  final String title;
  final String purpose;
  final String court;
  final String judge;
  final String time;

  const CauseListEntry({
    required this.serial,
    required this.cnr,
    required this.caseNumber,
    required this.title,
    required this.purpose,
    required this.court,
    required this.judge,
    required this.time,
  });

  factory CauseListEntry.fromJson(Map<String, dynamic> json) => CauseListEntry(
        serial: (json['serial'] as num?)?.toInt() ?? 0,
        cnr: _str(json['cnr']),
        caseNumber: _str(json['caseNumber']),
        title: _str(json['title']),
        purpose: _str(json['purpose']),
        court: _str(json['court']),
        judge: _str(json['judge']),
        time: _str(json['time']),
      );

  @override
  List<Object?> get props => [serial, cnr, caseNumber, title, court];
}

/// A lightweight hit from a party/advocate/filing-number search.
class CaseSearchHit extends Equatable {
  final String cnr;
  final String caseNumber;
  final String title;
  final String court;
  final String caseStatus;

  const CaseSearchHit({
    required this.cnr,
    required this.caseNumber,
    required this.title,
    required this.court,
    required this.caseStatus,
  });

  factory CaseSearchHit.fromJson(Map<String, dynamic> json) => CaseSearchHit(
        cnr: _str(json['cnr']),
        caseNumber: _str(json['caseNumber']),
        title: _str(json['title']),
        court: _str(json['court']),
        caseStatus: _str(json['caseStatus']),
      );

  @override
  List<Object?> get props => [cnr, caseNumber, title, court, caseStatus];
}

/// A court in the establishment directory returned by the enumerations endpoint.
class CourtRef extends Equatable {
  final String code;
  final String name;
  final String state;

  const CourtRef({required this.code, required this.name, required this.state});

  factory CourtRef.fromJson(Map<String, dynamic> json) => CourtRef(
        code: _str(json['code']),
        name: _str(json['name']),
        state: _str(json['state']),
      );

  @override
  List<Object?> get props => [code, name, state];
}
