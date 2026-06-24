import 'ecourts_models.dart';

/// Contract for the eCourts India case-data API (the "Partner API").
///
/// The interface is split from its implementation on purpose. Today the app
/// ships [MockEcourtsApi], which serves placeholder records with simulated
/// latency so the UI can be built and demoed without a key. A production
/// implementation would issue HTTPS requests against the documented endpoints,
/// forwarding an `X-API-Key` header, and parse the JSON onto the models in
/// `ecourts_models.dart` via their `fromJson` factories — nothing above this
/// layer changes.
///
/// Endpoint map (base: `https://api.ecourtsindia.com/v1`):
///
/// | Method                | Verb & path                          | Auth |
/// |-----------------------|--------------------------------------|------|
/// | [enumerations]        | GET  /enumerations                   | free |
/// | [courts]              | GET  /courts                         | free |
/// | [caseByCnr]           | GET  /cases/{cnr}                     | key  |
/// | [searchCases]         | GET  /cases/search                   | key  |
/// | [refreshCases]        | POST /cases/refresh                  | key  |
/// | [ordersByCnr]         | GET  /cases/{cnr}/orders             | key  |
/// | [ordersByCourtDate]   | GET  /orders?court={code}&date={d}   | key  |
/// | [latestOrders]        | GET  /orders/latest                  | key  |
/// | [causeList]           | GET  /cause-list                     | key  |
abstract class EcourtsApi {
  /// Live enumeration codes — case types, statuses and the court directory.
  /// Free and unauthenticated on the real API.
  Future<Enumerations> enumerations();

  /// The court-establishment directory (a slice of [enumerations] for callers
  /// that only need the courts).
  Future<List<CourtRef>> courts();

  /// The full record for a single case, looked up by its 16-character CNR.
  ///
  /// Throws [InvalidCnrException] when [cnr] isn't a well-formed CNR and
  /// [CaseNotFoundException] when no case carries it.
  Future<EcourtsCase> caseByCnr(String cnr);

  /// Searches cases by party name, advocate, filing number or FIR number.
  Future<CaseSearchResult> searchCases(CaseSearchQuery query);

  /// Queues up to 50 CNRs for a re-scrape from the portal. CNRs already held
  /// come back as `refreshed`, new ones as `queued`, and malformed ones as
  /// `invalid`. Built for nightly sync jobs.
  Future<RefreshResult> refreshCases(List<String> cnrs);

  /// Orders and judgments filed on a single case.
  Future<List<EcourtsOrder>> ordersByCnr(String cnr);

  /// Orders published by one court on a given date.
  Future<List<EcourtsOrder>> ordersByCourtDate(String courtCode, DateTime date);

  /// The most recent orders across all tracked cases, newest first.
  Future<List<EcourtsOrder>> latestOrders({int limit = 20});

  /// The daily cause list — matters scheduled before a court on a date.
  Future<List<CauseListEntry>> causeList(CauseListQuery query);
}

/// Helpers for the Case Number Record (CNR): the 16-character national case ID.
///
/// A CNR is `[6-char establishment][6-digit serial][4-digit year]`, e.g.
/// `MHAU01` + `990011` + `2024` → `MHAU019900112024`, conventionally written
/// grouped as `MHAU01-990011-2024`.
class Cnr {
  Cnr._();

  static final _shape = RegExp(r'^[A-Z0-9]{16}$');
  static final _nonAlnum = RegExp(r'[^A-Za-z0-9]');

  /// Upper-cases and strips spaces, dashes and other separators.
  static String normalize(String raw) =>
      raw.replaceAll(_nonAlnum, '').toUpperCase();

  /// Whether [raw] is a well-formed CNR once normalized.
  static bool isValid(String raw) => _shape.hasMatch(normalize(raw));

  /// The three logical blocks of a CNR, for display. Returns the whole string
  /// as a single block when it isn't 16 characters.
  static List<String> segments(String raw) {
    final n = normalize(raw);
    if (n.length != 16) return [n];
    return [n.substring(0, 6), n.substring(6, 12), n.substring(12)];
  }

  /// `MHAU01-990011-2024` grouped form, or the normalized string if it isn't a
  /// full CNR.
  static String format(String raw) {
    final parts = segments(raw);
    return parts.length == 3 ? parts.join('-') : parts.first;
  }
}

/// A party/advocate/filing/FIR search request. All fields are optional; the
/// API matches on whichever are supplied.
class CaseSearchQuery {
  final String? partyName;
  final String? advocateName;
  final String? filingNumber;
  final String? firNumber;
  final String? courtCode;
  final int? year;

  const CaseSearchQuery({
    this.partyName,
    this.advocateName,
    this.filingNumber,
    this.firNumber,
    this.courtCode,
    this.year,
  });

  bool get isEmpty =>
      (partyName ?? advocateName ?? filingNumber ?? firNumber)?.trim().isEmpty ??
      true;

  Map<String, dynamic> toQueryParameters() => {
        if (partyName != null) 'party': partyName,
        if (advocateName != null) 'advocate': advocateName,
        if (filingNumber != null) 'filingNumber': filingNumber,
        if (firNumber != null) 'firNumber': firNumber,
        if (courtCode != null) 'court': courtCode,
        if (year != null) 'year': year,
      };
}

/// Page of search hits plus the total the query matched.
class CaseSearchResult {
  final List<CaseSearchHit> hits;
  final int total;

  const CaseSearchResult({required this.hits, required this.total});
}

/// A cause-list request for [date], optionally narrowed to one court or case.
class CauseListQuery {
  final DateTime date;
  final String? courtCode;
  final String? cnr;

  const CauseListQuery({required this.date, this.courtCode, this.cnr});
}

/// Outcome of a [EcourtsApi.refreshCases] call, bucketed by what happened.
class RefreshResult {
  final List<String> refreshed;
  final List<String> queued;
  final List<String> invalid;

  const RefreshResult({
    required this.refreshed,
    required this.queued,
    required this.invalid,
  });

  int get accepted => refreshed.length + queued.length;
}

/// The free enumeration payload: lookup codes plus the court directory.
class Enumerations {
  final List<String> caseTypes;
  final List<String> caseStatuses;
  final List<CourtRef> courts;

  const Enumerations({
    required this.caseTypes,
    required this.caseStatuses,
    required this.courts,
  });
}

/// Base type for every failure surfaced by an [EcourtsApi].
class EcourtsException implements Exception {
  final String message;
  const EcourtsException(this.message);
  @override
  String toString() => message;
}

/// The supplied CNR wasn't a well-formed 16-character record number.
class InvalidCnrException extends EcourtsException {
  const InvalidCnrException(
      [super.message = 'That doesn\'t look like a 16-character CNR.']);
}

/// No case in the portal carries the requested CNR.
class CaseNotFoundException extends EcourtsException {
  final String cnr;
  const CaseNotFoundException(this.cnr)
      : super('No case found for that CNR.');
}

/// The API key was missing, invalid or out of credits.
class EcourtsAuthException extends EcourtsException {
  const EcourtsAuthException(
      [super.message = 'Your eCourts API key was rejected.']);
}

/// Too many requests in the current window.
class EcourtsRateLimitException extends EcourtsException {
  const EcourtsRateLimitException(
      [super.message = 'Rate limit reached. Try again in a moment.']);
}
