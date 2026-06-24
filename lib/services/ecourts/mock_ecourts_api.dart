import 'ecourts_api.dart';
import 'ecourts_models.dart';

/// A placeholder [EcourtsApi] that serves a small hand-built dataset with
/// simulated network latency, so the Case Status screen can be built and
/// demoed without an API key or connectivity.
///
/// It honours the real contract — validating CNRs, throwing the same
/// exceptions, and filtering search the way the live service does — so the only
/// thing that changes when a real client is swapped in is the construction of
/// this object. The sample CNRs below resolve; anything else 404s.
class MockEcourtsApi implements EcourtsApi {
  /// Cases keyed by normalized CNR. Built once, lazily, since the records carry
  /// non-const [DateTime]s.
  late final Map<String, EcourtsCase> _db = {
    for (final c in _seedCases()) c.cnr: c,
  };

  /// Mimics a round-trip so loading states are exercised in the UI.
  Future<T> _latency<T>(T value, [int ms = 420]) =>
      Future.delayed(Duration(milliseconds: ms), () => value);

  @override
  Future<Enumerations> enumerations() => _latency(
        const Enumerations(
          caseTypes: [
            'Civil Suit',
            'Criminal Case',
            'Writ Petition',
            'Matrimonial Case',
            'Company Petition',
            'Execution Petition',
          ],
          caseStatuses: ['Pending', 'Disposed'],
          courts: _courts,
        ),
        180,
      );

  @override
  Future<List<CourtRef>> courts() => _latency(_courts, 180);

  @override
  Future<EcourtsCase> caseByCnr(String cnr) async {
    if (!Cnr.isValid(cnr)) throw const InvalidCnrException();
    final found = _db[Cnr.normalize(cnr)];
    if (found == null) throw CaseNotFoundException(Cnr.normalize(cnr));
    return _latency(found, 520);
  }

  @override
  Future<CaseSearchResult> searchCases(CaseSearchQuery query) async {
    if (query.isEmpty) {
      return _latency(const CaseSearchResult(hits: [], total: 0), 200);
    }
    final party = query.partyName?.toLowerCase().trim();
    final advocate = query.advocateName?.toLowerCase().trim();
    final filing = query.filingNumber?.toLowerCase().trim();
    final fir = query.firNumber?.toLowerCase().trim();

    bool matches(EcourtsCase c) {
      final parties = [...c.petitioners, ...c.respondents];
      if (party != null && party.isNotEmpty) {
        if (!parties.any((p) => p.name.toLowerCase().contains(party))) {
          return false;
        }
      }
      if (advocate != null && advocate.isNotEmpty) {
        if (!parties.any(
            (p) => (p.advocate ?? '').toLowerCase().contains(advocate))) {
          return false;
        }
      }
      if (filing != null && filing.isNotEmpty) {
        if (!c.filingNumber.toLowerCase().contains(filing)) return false;
      }
      if (fir != null && fir.isNotEmpty) {
        if (!(c.fir?.firNumber.toLowerCase().contains(fir) ?? false)) {
          return false;
        }
      }
      return true;
    }

    final hits = _db.values.where(matches).map((c) => CaseSearchHit(
          cnr: c.cnr,
          caseNumber: c.registrationNumber,
          title: c.title,
          court: c.source,
          caseStatus: c.status.caseStatus,
        ));
    final list = hits.toList();
    return _latency(CaseSearchResult(hits: list, total: list.length), 460);
  }

  @override
  Future<RefreshResult> refreshCases(List<String> cnrs) async {
    final refreshed = <String>[];
    final queued = <String>[];
    final invalid = <String>[];
    final seen = <String>{};
    for (final raw in cnrs.take(50)) {
      final cnr = Cnr.normalize(raw);
      if (!Cnr.isValid(cnr) || !seen.add(cnr)) {
        if (!Cnr.isValid(cnr)) invalid.add(raw);
        continue;
      }
      (_db.containsKey(cnr) ? refreshed : queued).add(cnr);
    }
    return _latency(
      RefreshResult(refreshed: refreshed, queued: queued, invalid: invalid),
      600,
    );
  }

  @override
  Future<List<EcourtsOrder>> ordersByCnr(String cnr) async {
    if (!Cnr.isValid(cnr)) throw const InvalidCnrException();
    final found = _db[Cnr.normalize(cnr)];
    if (found == null) throw CaseNotFoundException(Cnr.normalize(cnr));
    return _latency(found.orders, 320);
  }

  @override
  Future<List<EcourtsOrder>> ordersByCourtDate(
      String courtCode, DateTime date) async {
    bool sameDay(DateTime? d) =>
        d != null &&
        d.year == date.year &&
        d.month == date.month &&
        d.day == date.day;
    final orders =
        _db.values.expand((c) => c.orders).where((o) => sameDay(o.date)).toList()
          ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return _latency(orders, 320);
  }

  @override
  Future<List<EcourtsOrder>> latestOrders({int limit = 20}) async {
    final orders = _db.values.expand((c) => c.orders).toList()
      ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return _latency(orders.take(limit).toList(), 320);
  }

  @override
  Future<List<CauseListEntry>> causeList(CauseListQuery query) async {
    var entries = _causeList;
    if (query.cnr != null) {
      final cnr = Cnr.normalize(query.cnr!);
      entries = entries.where((e) => Cnr.normalize(e.cnr) == cnr).toList();
    }
    if (query.courtCode != null) {
      entries = entries
          .where((e) => e.court
              .toLowerCase()
              .contains(query.courtCode!.toLowerCase()))
          .toList();
    }
    return _latency(entries, 400);
  }

  // --- Placeholder dataset -------------------------------------------------

  static const _courts = <CourtRef>[
    CourtRef(code: 'DLHC01', name: 'High Court of Delhi', state: 'Delhi'),
    CourtRef(
        code: 'MHAU01',
        name: 'District & Sessions Court, Aurangabad',
        state: 'Maharashtra'),
    CourtRef(
        code: 'KAHC02', name: 'High Court of Karnataka', state: 'Karnataka'),
  ];

  /// Three fully-fleshed records. The first two mirror the cases already in
  /// `LegalRepository` so a lookup feels continuous with the rest of the app;
  /// the third is a disposed matter, to exercise that state.
  List<EcourtsCase> _seedCases() => [
        EcourtsCase(
          cnr: 'DLHC010099882024',
          caseType: 'Civil Suit',
          filingNumber: 'CS/4471/2024',
          filingDate: DateTime(2024, 5, 28),
          registrationNumber: '2024-CV-0847',
          registrationDate: DateTime(2024, 6, 3),
          source: 'High Court of Delhi',
          fetchedAt: DateTime(2026, 6, 24, 7, 15),
          status: EcourtsCaseStatus(
            stage: 'Arguments',
            caseStatus: 'Pending',
            firstHearingDate: DateTime(2024, 7, 12),
            nextHearingDate: DateTime(2026, 6, 28),
            courtNumberAndJudge: 'Court No. 12 — Hon\'ble Justice R. Khanna',
          ),
          petitioners: const [
            EcourtsParty(name: 'Daniel Smith', advocate: 'Adv. Alex Carter'),
          ],
          respondents: const [
            EcourtsParty(name: 'Marcus Johnson', advocate: 'Adv. P. Iyer'),
          ],
          acts: const [
            EcourtsAct(act: 'Indian Contract Act, 1872', section: 's. 73'),
            EcourtsAct(act: 'Specific Relief Act, 1963', section: 's. 34'),
          ],
          history: [
            EcourtsHearing(
              businessOnDate: DateTime(2026, 5, 30),
              nextDate: DateTime(2026, 6, 28),
              purpose: 'Arguments',
              judge: 'Hon\'ble Justice R. Khanna',
            ),
            EcourtsHearing(
              businessOnDate: DateTime(2026, 4, 18),
              nextDate: DateTime(2026, 5, 30),
              purpose: 'Framing of issues',
              judge: 'Hon\'ble Justice R. Khanna',
            ),
            EcourtsHearing(
              businessOnDate: DateTime(2024, 7, 12),
              nextDate: DateTime(2026, 4, 18),
              purpose: 'Appearance',
              judge: 'Hon\'ble Justice S. Mehra',
            ),
          ],
          orders: [
            EcourtsOrder(
              number: 3,
              name: 'Order on interim injunction',
              date: DateTime(2026, 5, 30),
              url: 'https://judgments.ecourts.gov.in/DLHC010099882024/3.pdf',
            ),
            EcourtsOrder(
              number: 2,
              name: 'Issues framed',
              date: DateTime(2026, 4, 18),
              url: 'https://judgments.ecourts.gov.in/DLHC010099882024/2.pdf',
            ),
            EcourtsOrder(
              number: 1,
              name: 'Summons issued',
              date: DateTime(2024, 7, 12),
              url: 'https://judgments.ecourts.gov.in/DLHC010099882024/1.pdf',
            ),
          ],
        ),
        EcourtsCase(
          cnr: 'MHAU019900112024',
          caseType: 'Criminal Case',
          filingNumber: 'CC/9921/2024',
          filingDate: DateTime(2024, 4, 30),
          registrationNumber: '2024-CR-0312',
          registrationDate: DateTime(2024, 5, 6),
          source: 'District & Sessions Court, Aurangabad',
          fetchedAt: DateTime(2026, 6, 24, 7, 15),
          status: EcourtsCaseStatus(
            stage: 'Evidence',
            caseStatus: 'Pending',
            firstHearingDate: DateTime(2024, 6, 1),
            nextHearingDate: DateTime(2026, 6, 25),
            courtNumberAndJudge:
                'Court No. 4 — Hon\'ble Addl. Sessions Judge V. Patil',
          ),
          petitioners: const [
            EcourtsParty(name: 'State of Maharashtra'),
          ],
          respondents: const [
            EcourtsParty(name: 'Rohan Mehta', advocate: 'Adv. Alex Carter'),
          ],
          acts: const [
            EcourtsAct(act: 'Indian Penal Code, 1860', section: 's. 420'),
            EcourtsAct(act: 'Indian Penal Code, 1860', section: 's. 468'),
          ],
          fir: const EcourtsFir(
            policeStation: 'Aurangabad City Chowk',
            firNumber: '0188',
            year: '2024',
          ),
          history: [
            EcourtsHearing(
              businessOnDate: DateTime(2026, 5, 27),
              nextDate: DateTime(2026, 6, 25),
              purpose: 'Prosecution evidence',
              judge: 'Hon\'ble Addl. Sessions Judge V. Patil',
            ),
            EcourtsHearing(
              businessOnDate: DateTime(2026, 3, 14),
              nextDate: DateTime(2026, 5, 27),
              purpose: 'Charge',
              judge: 'Hon\'ble Addl. Sessions Judge V. Patil',
            ),
          ],
          orders: [
            EcourtsOrder(
              number: 2,
              name: 'Charge framed under s. 420 / 468 IPC',
              date: DateTime(2026, 3, 14),
              url: 'https://judgments.ecourts.gov.in/MHAU019900112024/2.pdf',
            ),
            EcourtsOrder(
              number: 1,
              name: 'Bail granted with conditions',
              date: DateTime(2024, 5, 26),
              url: 'https://judgments.ecourts.gov.in/MHAU019900112024/1.pdf',
            ),
          ],
        ),
        EcourtsCase(
          cnr: 'KAHC020045672023',
          caseType: 'Writ Petition',
          filingNumber: 'WP/1204/2023',
          filingDate: DateTime(2023, 2, 9),
          registrationNumber: '2023-WP-1204',
          registrationDate: DateTime(2023, 2, 15),
          source: 'High Court of Karnataka',
          fetchedAt: DateTime(2026, 6, 24, 7, 15),
          status: EcourtsCaseStatus(
            stage: 'Disposed',
            caseStatus: 'Disposed',
            firstHearingDate: DateTime(2023, 3, 1),
            decisionDate: DateTime(2025, 11, 20),
            natureOfDisposal: 'Allowed',
            courtNumberAndJudge: 'Court No. 7 — Hon\'ble Justice A. Rao',
          ),
          petitioners: const [
            EcourtsParty(name: 'Lakshmi Rao', advocate: 'Adv. N. Shetty'),
          ],
          respondents: const [
            EcourtsParty(name: 'Union of India', advocate: 'ASG K. Menon'),
          ],
          acts: const [
            EcourtsAct(
                act: 'Constitution of India', section: 'Art. 226'),
          ],
          history: [
            EcourtsHearing(
              businessOnDate: DateTime(2025, 11, 20),
              nextDate: null,
              purpose: 'Judgment pronounced',
              judge: 'Hon\'ble Justice A. Rao',
            ),
            EcourtsHearing(
              businessOnDate: DateTime(2025, 9, 4),
              nextDate: DateTime(2025, 11, 20),
              purpose: 'Final arguments',
              judge: 'Hon\'ble Justice A. Rao',
            ),
          ],
          orders: [
            EcourtsOrder(
              number: 1,
              name: 'Final judgment — petition allowed',
              date: DateTime(2025, 11, 20),
              url: 'https://judgments.ecourts.gov.in/KAHC020045672023/1.pdf',
            ),
          ],
        ),
      ];

  /// A short daily cause list for the demo "today" (24 Jun 2026).
  static const _causeList = <CauseListEntry>[
    CauseListEntry(
      serial: 14,
      cnr: 'MHAU019900112024',
      caseNumber: '2024-CR-0312',
      title: 'State of Maharashtra vs Rohan Mehta',
      purpose: 'Prosecution evidence',
      court: 'District & Sessions Court, Aurangabad',
      judge: 'ASJ V. Patil',
      time: '11:00 AM',
    ),
    CauseListEntry(
      serial: 22,
      cnr: 'DLHC010099882024',
      caseNumber: '2024-CV-0847',
      title: 'Daniel Smith vs Marcus Johnson',
      purpose: 'Arguments',
      court: 'High Court of Delhi',
      judge: 'Justice R. Khanna',
      time: '02:15 PM',
    ),
    CauseListEntry(
      serial: 31,
      cnr: 'DLHC010044192025',
      caseNumber: '2025-CV-1190',
      title: 'Verma Textiles vs Apex Logistics',
      purpose: 'Admission',
      court: 'High Court of Delhi',
      judge: 'Justice R. Khanna',
      time: '03:00 PM',
    ),
  ];
}
