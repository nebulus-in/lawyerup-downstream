import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'ecourts_api.dart';
import 'ecourts_models.dart';

/// A live [EcourtsApi] backed by the server-side eCourtsIndia proxy.
///
/// The proxy (see [baseUrl]) attaches the partner Bearer token upstream, so
/// this client carries no secret — it only shapes requests and maps the proxy's
/// JSON onto the app's models. It is a drop-in for `MockEcourtsApi`: the
/// [EcourtsBloc] and everything above the service layer are untouched.
///
/// The proxy nests most payloads under a top-level `data` envelope and resolves
/// enum codes (case type, status, court) through a `descriptions.enumLookup`
/// block on the case detail, which we use for human-readable display.
class HttpEcourtsApi implements EcourtsApi {
  HttpEcourtsApi({String baseUrl = defaultBaseUrl, http.Client? client})
      : _base = Uri.parse(baseUrl),
        _client = client ?? http.Client();

  /// The deployed proxy. Override [baseUrl] in tests or for a self-hosted copy.
  static const defaultBaseUrl = 'https://unsettled-backend.vercel.app';

  final Uri _base;
  final http.Client _client;

  static const _read = Duration(seconds: 60);
  // Case detail can trigger a first-time scrape upstream, so give it room.
  static const _caseRead = Duration(seconds: 90);

  static const _headers = {'Accept': 'application/json'};

  @override
  void dispose() => _client.close();

  // --- Case data -----------------------------------------------------------

  @override
  Future<EcourtsCase> caseByCnr(String cnr) async {
    if (!Cnr.isValid(cnr)) throw const InvalidCnrException();
    final norm = Cnr.normalize(cnr);
    if (await _cacheGet('case:$norm') case final EcourtsCase hit) return hit;
    final resp = await _send(
      () => _client.get(_uri('/api/partner/case/$norm'), headers: _headers),
      _caseRead,
    );
    if (resp.statusCode == 404) throw CaseNotFoundException(norm);
    if (resp.statusCode == 400) throw const InvalidCnrException();
    final body = _decodeObject(resp);
    final data = (body['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) throw CaseNotFoundException(norm);
    final result = _caseFromDetail(data);
    await _cachePut('case:$norm', result);
    return result;
  }

  @override
  Future<CaseSearchResult> searchCases(CaseSearchQuery query) async {
    if (query.isEmpty) return const CaseSearchResult(hits: [], total: 0);

    final params = <String, dynamic>{};
    void put(String k, String? v) {
      if (v != null && v.trim().isNotEmpty) params[k] = v.trim();
    }

    // Targeted text params map straight onto the registry's search fields.
    put('query', query.query);
    put('advocates', query.advocateName);
    put('judges', query.judgeName);
    put('litigants', query.partyName);
    if ((query.caseStatuses ?? const []).isNotEmpty) {
      params['caseStatuses'] = query.caseStatuses; // repeated array param
    }
    if (query.nextHearingFrom != null) {
      params['nextHearingDateFrom'] = _ymd(query.nextHearingFrom!);
    }
    if (query.nextHearingTo != null) {
      params['nextHearingDateTo'] = _ymd(query.nextHearingTo!);
    }
    put('sortBy', query.sortBy);
    put('sortOrder', query.sortOrder);
    if (query.courtCode != null) params['courtCodes'] = query.courtCode;

    final key = 'search:${_stableKey(params)}';
    if (await _cacheGet(key) case final CaseSearchResult hit) return hit;

    final body = await _getJson('/api/partner/search', params: params);
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final hits = _objList(data['results']).map((r) {
      final pet = _strList(r['petitioners']);
      final res = _strList(r['respondents']);
      final reg = _str(r['registrationNumber']);
      return CaseSearchHit(
        cnr: _str(r['cnr']),
        caseNumber: reg.isNotEmpty ? reg : _str(r['filingNumber']),
        title:
            '${pet.isEmpty ? 'Unknown' : pet.first} vs ${res.isEmpty ? 'Unknown' : res.first}',
        court: _str(r['courtName']),
        caseStatus: _str(r['caseStatus']),
      );
    }).toList();
    final total = _int(data['totalCount'],
        _int(data['returnedCount'], hits.length));
    final result = CaseSearchResult(hits: hits, total: total);
    await _cachePut(key, result);
    return result;
  }

  @override
  Future<RefreshResult> refreshCases(List<String> cnrs) async {
    final valid = <String>[];
    final invalid = <String>[];
    final seen = <String>{};
    for (final raw in cnrs.take(50)) {
      final cnr = Cnr.normalize(raw);
      if (!Cnr.isValid(cnr)) {
        invalid.add(raw);
      } else if (seen.add(cnr)) {
        valid.add(cnr);
      }
    }
    if (valid.isEmpty) {
      return RefreshResult(refreshed: const [], queued: const [], invalid: invalid);
    }

    final endpoint = valid.length == 1
        ? '/api/partner/case/${valid.first}/refresh'
        : '/api/partner/case/bulk-refresh';
    final body = await _postJson(
      endpoint,
      valid.length == 1 ? const {} : {'cnrs': valid},
    );

    final data = (body['data'] as Map?)?.cast<String, dynamic>();
    if (data != null) {
      final refreshed = _strList(data['refreshed']);
      final queued = _strList(data['queued']);
      final invFromServer = _strList(data['invalid']);
      if (refreshed.isNotEmpty || queued.isNotEmpty || invFromServer.isNotEmpty) {
        return RefreshResult(
          refreshed: refreshed,
          queued: queued,
          invalid: [...invalid, ...invFromServer],
        );
      }
    }
    // Accepted but unbucketed — everything we sent is now queued upstream.
    return RefreshResult(refreshed: const [], queued: valid, invalid: invalid);
  }

  @override
  Future<List<EcourtsOrder>> ordersByCnr(String cnr) async =>
      (await caseByCnr(cnr)).orders;

  // The proxy has no cross-case order feed; these stay unsupported rather than
  // faking data. The Case Status UI doesn't call them.
  @override
  Future<List<EcourtsOrder>> ordersByCourtDate(
          String courtCode, DateTime date) async =>
      const [];

  @override
  Future<List<EcourtsOrder>> latestOrders({int limit = 20}) async => const [];

  // --- Cause list ----------------------------------------------------------

  @override
  Future<List<CauseListEntry>> causeList(CauseListQuery query) async {
    final params = <String, dynamic>{'date': _ymd(query.date)};
    if (query.courtCode != null) params['court'] = query.courtCode;
    if (query.cnr != null) params['query'] = query.cnr;

    final key = 'cause:${params['date']}:${query.courtCode ?? ''}:${query.cnr ?? ''}';
    if (await _cacheGet(key) case final List<CauseListEntry> hit) return hit;

    final body = await _getJson('/api/partner/causelist/search', params: params);
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final results = _objList(data['results']);
    var i = 0;
    final entries = results.map((e) {
      i++;
      // The proxy preformats the cause-title in `party`; fall back to the
      // petitioner/respondent arrays. `caseNumber` and `judge` arrive as lists.
      final party = _str(e['party']);
      final pet = _strList(e['petitioners']);
      final res = _strList(e['respondents']);
      final caseNo = _flat(e['caseNumber']);
      return CauseListEntry(
        serial: _int(e['listingNo'] ?? e['serialNumber'] ?? e['serial'], i),
        cnr: _str(e['cnr']),
        caseNumber: caseNo.isNotEmpty ? caseNo : _str(e['internalCaseNo']),
        title: party.isNotEmpty
            ? party
            : (pet.isEmpty && res.isEmpty
                ? ''
                : '${pet.isEmpty ? '' : pet.first} vs ${res.isEmpty ? '' : res.first}'),
        purpose: _first([_str(e['purpose']), _str(e['status'])]),
        court: _first(
            [_str(e['courtName']), _str(e['courtDescription']), _str(e['court'])]),
        judge: _flat(e['judge']),
        time: _first([_str(e['time']), _str(e['hearingTime'])]),
      );
    }).toList();
    await _cachePut(key, entries);
    return entries;
  }

  // --- Enumerations --------------------------------------------------------

  @override
  Future<Enumerations> enumerations() async {
    final body = await _getJson('/api/partner/enums',
        params: {'types': 'caseType,caseStatus,courtCode'});
    final enums =
        ((body['data'] as Map?)?['enums'] as Map?)?.cast<String, dynamic>() ??
            const {};
    List<String> descriptions(String key) => _objList(enums[key])
        .map((e) {
          final d = _str(e['description']);
          return d.isNotEmpty ? d : _str(e['code']);
        })
        .where((s) => s.isNotEmpty)
        .toList();
    final courts = _objList(enums['courtCode'])
        .map((e) =>
            CourtRef(code: _str(e['code']), name: _str(e['description']), state: ''))
        .toList();
    return Enumerations(
      caseTypes: descriptions('caseType'),
      caseStatuses: descriptions('caseStatus'),
      courts: courts,
    );
  }

  @override
  Future<List<CourtRef>> courts() async => (await enumerations()).courts;

  // --- Mapping -------------------------------------------------------------

  EcourtsCase _caseFromDetail(Map<String, dynamic> data) {
    final cc = (data['courtCaseData'] as Map?)?.cast<String, dynamic>() ?? const {};
    final entity = (data['entityInfo'] as Map?)?.cast<String, dynamic>() ?? const {};
    final lookup = ((data['descriptions'] as Map?)?['enumLookup'] as Map?)
            ?.cast<String, dynamic>() ??
        const {};

    String resolve(String field, String code) {
      if (code.isEmpty) return code;
      final value = (lookup[field] as Map?)?[code];
      final s = value?.toString() ?? '';
      return s.isEmpty ? code : s;
    }

    final cnr = _str(cc['cnr']);
    final courtCode = _first([_str(cc['cnrCourtCode']), _str(cc['courtComplexCode'])]);
    final statusCode = _str(cc['caseStatus']);

    final history = _objList(cc['historyOfCaseHearings'])
        .map((h) => EcourtsHearing(
              businessOnDate: _date(h['businessOnDate']),
              nextDate: _date(h['nextDate'] ?? h['nextHearingDate']),
              purpose: _str(h['purposeOfListing'] ?? h['purpose']),
              judge: _str(h['judge']),
            ))
        .toList();

    // Judgments and interim orders share one list in the UI, newest first.
    final rawOrders = [
      ..._objList(cc['judgmentOrders']),
      ..._objList(cc['interimOrders']),
    ];
    var n = rawOrders.length;
    final orders = rawOrders.map((o) {
      final file = _first([_str(o['orderUrl']), _str(o['fileName']), _str(o['file'])]);
      final type = _str(o['orderType']);
      return EcourtsOrder(
        number: n--,
        name: type.isNotEmpty ? type : 'Order',
        date: _date(o['orderDate'] ?? o['date']),
        url: file.isEmpty
            ? ''
            : '${_base.origin}/api/partner/case/$cnr/order-md/$file',
      );
    }).toList();

    final acts = <EcourtsAct>[];
    final rawActs = cc['actsAndSections'];
    if (rawActs is List) {
      for (final a in rawActs) {
        if (a is Map) {
          acts.add(EcourtsAct(
            act: _str(a['act']),
            section: _str(a['section'] ?? a['underSection']),
          ));
        } else if (a is String && a.trim().isNotEmpty) {
          acts.add(EcourtsAct(act: a.trim(), section: ''));
        }
      }
    }

    final firMap =
        (cc['firDetails'] as Map?)?.cast<String, dynamic>() ?? const {};
    EcourtsFir? fir;
    if (firMap.isNotEmpty) {
      final station = _first([
        _str(firMap['policeStation']),
        _str(firMap['policeStationName']),
      ]);
      final firNo = _first([_str(firMap['firNumber']), _str(firMap['firNo'])]);
      if (station.isNotEmpty || firNo.isNotEmpty) {
        fir = EcourtsFir(
          policeStation: station,
          firNumber: firNo,
          year: _first([_str(firMap['year']), _str(firMap['firYear'])]),
        );
      }
    }

    final isDisposed = statusCode.toLowerCase().contains('dispos') ||
        _date(cc['decisionDate']) != null;
    final disposal = _str(cc['disposalType']);
    final natureOfDisposal =
        (disposal.isEmpty || disposal.toUpperCase() == 'UNKNOWN') ? null : disposal;

    final judges = _strList(cc['judges']);
    final bench = _str(cc['benchName']);
    final judgeLabel =
        judges.isNotEmpty ? judges.join(', ') : (bench.isNotEmpty ? bench : '—');
    final courtNo = _str(cc['courtNo']);
    final courtNoPrefix =
        (courtNo.isEmpty || courtNo == '0') ? '' : 'Court No. $courtNo — ';
    final latestPurpose = history.isNotEmpty ? history.first.purpose : '';

    final status = EcourtsCaseStatus(
      stage: isDisposed
          ? 'Disposed'
          : (latestPurpose.isNotEmpty ? latestPurpose : resolve('caseStatus', statusCode)),
      caseStatus: resolve('caseStatus', statusCode),
      firstHearingDate: _date(cc['firstHearingDate']),
      nextHearingDate: _date(entity['nextDateOfHearing'] ?? cc['nextHearingDate']),
      decisionDate: _date(cc['decisionDate']),
      natureOfDisposal: natureOfDisposal,
      courtNumberAndJudge: '$courtNoPrefix$judgeLabel',
    );

    return EcourtsCase(
      cnr: cnr,
      caseType: resolve('caseType', _str(cc['caseType'])),
      filingNumber: _str(cc['filingNumber']),
      filingDate: _date(cc['filingDate']),
      registrationNumber: _str(cc['registrationNumber']),
      registrationDate: _date(cc['registrationDate']),
      status: status,
      petitioners:
          _parties(_strList(cc['petitioners']), _strList(cc['petitionerAdvocates'])),
      respondents:
          _parties(_strList(cc['respondents']), _strList(cc['respondentAdvocates'])),
      acts: acts,
      history: history,
      orders: orders,
      fir: fir,
      source: resolve('courtCode', courtCode),
      fetchedAt: _date(entity['dateModified']) ??
          _date(entity['lastDateOfHearing']) ??
          DateTime.now(),
    );
  }

  // --- 12h read cache ------------------------------------------------------
  // Static so it outlives the per-mount HttpEcourtsApi the view builds.
  // Persisted to the application documents directory to survive app restarts.

  static const _cacheTtl = Duration(hours: 12);
  static final _cache = <String, ({Object value, DateTime at})>{};
  static Future<void>? _initFuture;

  static bool fresh(DateTime at, DateTime now) =>
      now.difference(at) < _cacheTtl;

  static Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ecourts_cache.json');
  }

  static Future<void> _ensureInitialized() {
    return _initFuture ??= _doInitCache();
  }

  static Future<void> _doInitCache() async {
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final now = DateTime.now();
        var dirty = false;
        
        json.forEach((key, entry) {
          final at = DateTime.parse(entry['at'] as String);
          if (fresh(at, now)) {
            final val = entry['value'];
            Object? decoded;
            if (key.startsWith('case:')) {
              decoded = EcourtsCase.fromJson(val as Map<String, dynamic>);
            } else if (key.startsWith('search:')) {
              decoded = CaseSearchResult.fromJson(val as Map<String, dynamic>);
            } else if (key.startsWith('cause:')) {
              decoded = (val as List)
                  .map((e) => CauseListEntry.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
            if (decoded != null) {
              _cache[key] = (value: decoded, at: at);
            }
          } else {
            dirty = true;
          }
        });
        
        // If we skipped stale entries, update the disk file immediately to prune them.
        if (dirty) {
          unawaited(_saveCache());
        }
      }
    } catch (e) {
      debugPrint('Failed to load ecourts cache: $e');
    }
  }

  static Future<void> _saveCache() async {
    try {
      final file = await _getCacheFile();
      final json = <String, dynamic>{};
      _cache.forEach((key, entry) {
        dynamic val;
        final v = entry.value;
        if (v is EcourtsCase) val = v.toJson();
        else if (v is CaseSearchResult) val = v.toJson();
        else if (v is List<CauseListEntry>) val = v.map((e) => e.toJson()).toList();
        
        if (val != null) {
          json[key] = {'at': entry.at.toIso8601String(), 'value': val};
        }
      });
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Failed to save ecourts cache: $e');
    }
  }

  static Future<Object?> _cacheGet(String key) async {
    await _ensureInitialized();
    final e = _cache[key];
    if (e == null) return null;
    if (!fresh(e.at, DateTime.now())) {
      _cache.remove(key);
      unawaited(_saveCache());
      return null;
    }
    return e.value;
  }

  static Future<void> _cachePut(String key, Object value) async {
    await _ensureInitialized();
    _cache[key] = (value: value, at: DateTime.now());
    await _saveCache();
  }

  // --- HTTP plumbing -------------------------------------------------------

  Uri _uri(String path, [Map<String, dynamic>? params]) {
    // Values may be a single scalar or an Iterable, which Uri repeats as
    // `k=a&k=b` — how the registry takes array filters like caseStatuses.
    final qp = <String, dynamic>{};
    params?.forEach((k, v) {
      if (v == null) return;
      if (v is Iterable) {
        final items =
            v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        if (items.isNotEmpty) qp[k] = items;
      } else {
        qp[k] = v.toString();
      }
    });
    return _base.replace(path: path, queryParameters: qp.isEmpty ? null : qp);
  }

  Future<http.Response> _send(
      Future<http.Response> Function() run, Duration timeout) async {
    final http.Response resp;
    try {
      resp = await run().timeout(timeout);
    } on TimeoutException {
      throw const EcourtsException(
          'The eCourts service took too long to respond. Try again.');
    } catch (_) {
      throw const EcourtsException(
          "Couldn't reach the eCourts service. Check your connection.");
    }
    final s = resp.statusCode;
    if (s == 401 || s == 403) throw const EcourtsAuthException();
    if (s == 429) throw const EcourtsRateLimitException();
    return resp;
  }

  Future<Map<String, dynamic>> _getJson(String path,
      {Map<String, dynamic>? params, Duration timeout = _read}) async {
    final resp =
        await _send(() => _client.get(_uri(path, params), headers: _headers), timeout);
    return _decodeObject(resp);
  }

  Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> json,
      {Duration timeout = _read}) async {
    final resp = await _send(
      () => _client.post(
        _uri(path),
        headers: const {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(json),
      ),
      timeout,
    );
    return _decodeObject(resp);
  }

  Map<String, dynamic> _decodeObject(http.Response resp) {
    final body = _tryDecode(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return body is Map ? body.cast<String, dynamic>() : <String, dynamic>{};
    }
    throw EcourtsException(_errorMessage(body, resp.statusCode));
  }

  static dynamic _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  static String _errorMessage(dynamic body, int status) {
    if (body is Map) {
      final err = body['error'];
      if (err is Map && err['message'] != null) return err['message'].toString();
      if (body['message'] != null) return body['message'].toString();
    }
    return 'The eCourts service returned an error ($status).';
  }
}

// --- JSON helpers (the models' own parsers are library-private) -------------

String _str(dynamic v) => v?.toString() ?? '';

String _first(Iterable<String> candidates) =>
    candidates.firstWhere((s) => s.isNotEmpty, orElse: () => '');

/// Flattens a value that may be a single string or a list of strings (some
/// cause-list fields like `caseNumber` and `judge` arrive as arrays).
String _flat(dynamic v) {
  if (v is List) {
    return v
        .map((e) => e?.toString() ?? '')
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
  }
  return _str(v);
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString().trim();
  return s.isEmpty ? null : DateTime.tryParse(s);
}

int _int(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

List<Map<String, dynamic>> _objList(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

List<String> _strList(dynamic v) => v is List
    ? v.map((e) => e?.toString() ?? '').where((s) => s.trim().isNotEmpty).toList()
    : const [];

List<EcourtsParty> _parties(List<String> names, List<String> advocates) => [
      for (var i = 0; i < names.length; i++)
        EcourtsParty(
          name: names[i],
          advocate: i < advocates.length && advocates[i].trim().isNotEmpty
              ? advocates[i]
              : null,
        ),
    ];

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A deterministic cache key for a query-param map: keys sorted, list values
/// joined, so the same search always hits the same cache entry.
String _stableKey(Map<String, dynamic> params) {
  final keys = params.keys.toList()..sort();
  return keys.map((k) {
    final v = params[k];
    return '$k=${v is Iterable ? v.join('+') : v}';
  }).join('&');
}

void debugPrint(String s) => print(s);
