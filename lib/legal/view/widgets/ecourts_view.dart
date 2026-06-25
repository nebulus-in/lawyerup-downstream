import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../legal_theme.dart';
import '../../bloc/blocs.dart';
import '../../../models/legal_models.dart';
import '../../../services/ecourts/ecourts_api.dart';
import '../../../services/ecourts/ecourts_models.dart';
import '../../../services/ecourts/http_ecourts_api.dart';
import 'legal_modals.dart';

/// The eCourts "Case Status" destination: look a case up by its 16-character
/// CNR and read its live status straight from the (placeholder) eCourts API.
///
/// It owns its own [EcourtsBloc] backed by [HttpEcourtsApi], the live
/// server-side proxy client. (Swap in `MockEcourtsApi` for offline demos.)
class ECourtsView extends StatelessWidget {
  const ECourtsView({super.key});

  /// The id this screen occupies in [NavigationState.selectedSource], so the
  /// research router can tell it apart from a webview source.
  static const sourceId = 'ecourts';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: const ValueKey('ecourts'),
      create: (_) => EcourtsBloc(HttpEcourtsApi()),
      child: const _ECourtsScreen(),
    );
  }
}

// The lookup field, the result's dark CNR plate, and the cause-list rows all set
// machine identifiers in monospace so they read as "pulled from the register" —
// distinct from the sans used for people and prose. One type idea, used
// consistently, is this screen's signature.
const _mono = 'monospace';

const _amber = Color(0xFFE07A14);
const _amberBg = Color(0xFFFFF4EC);
const _green = Color(0xFF1A8A4A);
const _greenBg = Color(0xFFE8F5EE);

String _fmtDate(DateTime? d) =>
    d == null ? '—' : '${d.day} ${LegalTheme.monthAbbr[d.month - 1]} ${d.year}';

String _fmtSync(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${LegalTheme.monthAbbr[d.month - 1]} · $hh:$mm';
}

/// Maps an eCourts case type onto the app's own case-type vocabulary so an
/// imported case lands with the right colour and folder template.
String _appType(String caseType) {
  final t = caseType.toLowerCase();
  if (t.contains('crimin')) return 'CRIMINAL';
  if (t.contains('matrimon') || t.contains('family')) return 'FAMILY';
  if (t.contains('company') || t.contains('corporate')) return 'CORPORATE';
  return 'CIVIL';
}

class _ECourtsScreen extends StatefulWidget {
  const _ECourtsScreen();

  @override
  State<_ECourtsScreen> createState() => _ECourtsScreenState();
}

class _ECourtsScreenState extends State<_ECourtsScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-load a CNR passed in via NavigationBloc (e.g. from the case detail
    // "View Case Status" card). Consume it immediately so it doesn't re-trigger.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = context.read<NavigationBloc>();
      final cnr = nav.state.pendingCnr;
      if (cnr != null && cnr.isNotEmpty) {
        nav.add(const PendingCnrSet(null));
        _runCnr(cnr);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<EcourtsBloc>().add(EcourtsLookupRequested(_controller.text));
  }

  void _runCnr(String cnr) {
    _controller.text = Cnr.normalize(cnr);
    FocusScope.of(context).unfocus();
    context.read<EcourtsBloc>().add(EcourtsLookupRequested(cnr));
  }

  /// System back steps out of a result first, then leaves the screen — so a
  /// stray back press never drops the user straight out of research.
  void _onBack() {
    final bloc = context.read<EcourtsBloc>();
    if (bloc.state.status == EcourtsStatus.idle) {
      context.read<NavigationBloc>().add(const SourceSelected(null));
    } else {
      _controller.clear();
      bloc.add(const EcourtsResetRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Container(
        key: const ValueKey('ecourts_screen'),
        color: LegalTheme.page,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ECourtsHeader(onBack: _onBack),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _LookupCardSlot(
                      controller: _controller,
                      onSubmit: _submit,
                      onSample: _runCnr,
                    ),
                    const _Body(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ECourtsHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ECourtsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: LegalTheme.ink,
                borderRadius: BorderRadius.circular(9)),
            child: const Text('eC',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('eCourts',
                    style:
                        TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                Text('National case registry',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LegalTheme.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
                color: _greenBg, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                _Dot(color: _green),
                SizedBox(width: 5),
                Text('Live',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Wraps [_LookupCard] and hides it once a lookup is in flight or has a result,
/// so the result content gets the full vertical space. The card reappears when
/// the user resets back to idle.
class _LookupCardSlot extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final void Function(String) onSample;

  const _LookupCardSlot({
    required this.controller,
    required this.onSubmit,
    required this.onSample,
  });

  @override
  Widget build(BuildContext context) {
    final status = context.select((EcourtsBloc b) => b.state.status);
    final isIdle = status == EcourtsStatus.idle;

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      child: isIdle
          ? Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _LookupCard(
                controller: controller,
                onSubmit: onSubmit,
                onSample: onSample,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// The hero: the CNR lookup. Always on screen so a new search is one tap away.
class _LookupCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final void Function(String) onSample;

  const _LookupCard({
    required this.controller,
    required this.onSubmit,
    required this.onSample,
  });

  static const _samples = [
    'DLHC010099882024',
    'MHAU019900112024',
    'KAHC020045672023',
  ];

  @override
  Widget build(BuildContext context) {
    final loading = context.select(
        (EcourtsBloc b) => b.state.status == EcourtsStatus.loading);
    final recent = context.select((EcourtsBloc b) => b.state.recent);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: LegalTheme.cardDecoration(radius: 22, blur: 18, opacity: 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Look up a case',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: LegalTheme.ink)),
          const SizedBox(height: 4),
          const Text('Enter the 16-character CNR from any Indian court.',
              style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: LegalTheme.muted)),
          const SizedBox(height: 14),
          _CnrField(controller: controller, onSubmit: onSubmit),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: loading ? null : onSubmit,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: loading ? LegalTheme.muted : LegalTheme.blue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: loading
                    ? null
                    : [
                        BoxShadow(
                            color: LegalTheme.blue.withValues(alpha: 0.30),
                            blurRadius: 18,
                            offset: const Offset(0, 8))
                      ],
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Look up case',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          _CnrChips(
            label: recent.isEmpty ? 'Try a sample' : 'Recent',
            cnrs: recent.isEmpty ? _samples : recent,
            onTap: onSample,
          ),
        ],
      ),
    );
  }
}

/// Filters input to upper-case alphanumerics and caps it at the CNR's 16 chars.
class _CnrInputFormatter extends TextInputFormatter {
  static final _strip = RegExp(r'[^A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.toUpperCase().replaceAll(_strip, '');
    if (text.length > 16) text = text.substring(0, 16);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CnrField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _CnrField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LegalTheme.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LegalTheme.page),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: LegalTheme.page)),
            child: const Text('CNR',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: LegalTheme.muted)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              inputFormatters: [_CnrInputFormatter()],
              style: const TextStyle(
                fontFamily: _mono,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: LegalTheme.ink,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                border: InputBorder.none,
                hintText: 'MHAU01 990011 2024',
                hintStyle: TextStyle(
                  fontFamily: _mono,
                  fontSize: 14,
                  letterSpacing: 1,
                  color: Color(0xFFBCC4D0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CnrChips extends StatelessWidget {
  final String label;
  final List<String> cnrs;
  final void Function(String) onTap;

  const _CnrChips(
      {required this.label, required this.cnrs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: LegalTheme.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cnrs
              .map((c) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                          color: LegalTheme.blueBg,
                          borderRadius: BorderRadius.circular(9)),
                      child: Text(Cnr.format(c),
                          style: const TextStyle(
                              fontFamily: _mono,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: LegalTheme.blue)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// Swaps the body for the current lookup state.
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final status = context.select((EcourtsBloc b) => b.state.status);

    final Widget child = switch (status) {
      EcourtsStatus.success => _CaseResult(
          key: const ValueKey('result'),
          result: context.select((EcourtsBloc b) => b.state.result!),
        ),
      EcourtsStatus.loading =>
        const _ResultSkeleton(key: ValueKey('loading')),
      EcourtsStatus.notFound ||
      EcourtsStatus.invalid ||
      EcourtsStatus.error =>
        const _EmptyResult(key: ValueKey('empty')),
      EcourtsStatus.idle => const _IdleBody(key: ValueKey('idle')),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      child: child,
    );
  }
}

// --- Idle: search + today's cause list ----------------------------------------

/// The idle view: a scoped search over the registry, with today's cause list
/// as the resting state. Searching swaps the board for results; clearing brings
/// it back. A chosen result hands off to the CNR lookup to open in full.
class _IdleBody extends StatelessWidget {
  const _IdleBody({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select((EcourtsBloc b) => b.state.searchPhase);
    final query =
        context.select((EcourtsBloc b) => b.state.searchCriteria.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SearchPanel(),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          child: switch (phase) {
            SearchPhase.idle => const _BoardSection(key: ValueKey('board')),
            SearchPhase.loading =>
              _SearchBusy(query: query, key: const ValueKey('searching')),
            SearchPhase.error => const _SearchError(key: ValueKey('search-err')),
            SearchPhase.done => const _SearchResults(key: ValueKey('results')),
          },
        ),
      ],
    );
  }
}

/// The search input cluster: a scoped query field, a filters button, and chips
/// for whatever's active. The scope token leads the field — the same in-field
/// label the CNR field uses, but here it's a control that picks which column of
/// the register the text matches. The text stays sans (you're typing a person
/// or a phrase), distinct from the CNR field's monospace.
class _SearchPanel extends StatefulWidget {
  const _SearchPanel();

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  SearchCriteria get _criteria =>
      context.read<EcourtsBloc>().state.searchCriteria;

  void _submit(SearchCriteria c) =>
      context.read<EcourtsBloc>().add(EcourtsSearchSubmitted(c));

  void _openConsole() {
    final bloc = context.read<EcourtsBloc>();
    FocusScope.of(context).unfocus();
    _showSearchConsole(
      context,
      initial: bloc.state.searchCriteria,
      recents: bloc.state.recentSearches,
      onSubmit: _submit,
    );
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _submit(_criteria.copyWith(text: ''));
  }

  @override
  Widget build(BuildContext context) {
    final criteria = context.select((EcourtsBloc b) => b.state.searchCriteria);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.search_rounded, size: 16, color: LegalTheme.ink),
            SizedBox(width: 7),
            Text('Search the register',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: LegalTheme.ink)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Find a case by party, advocate or judge — no CNR needed.',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: LegalTheme.muted)),
        const SizedBox(height: 12),
        _SearchTrigger(
          scope: criteria.scope,
          query: criteria.text,
          onTap: _openConsole,
          onClear: criteria.text.trim().isEmpty ? null : _clear,
        ),
        _ActiveFilters(criteria: criteria, onChanged: _submit),
      ],
    );
  }
}

/// The resting search affordance: a tappable bar that opens the search console.
/// It looks like the field it replaces — leading scope token, the live query (or
/// a scope hint) — but it's a button. A clear control appears when a search is
/// live so a result set can be dropped without opening the console.
class _SearchTrigger extends StatelessWidget {
  final SearchScope scope;
  final String query;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SearchTrigger({
    required this.scope,
    required this.query,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE2EB)),
          boxShadow: [
            BoxShadow(
              color: LegalTheme.ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _ScopeToken(scope: scope, onTap: onTap),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasQuery ? query : _scopeHint(scope),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: hasQuery ? 15 : 14,
                  fontWeight: hasQuery ? FontWeight.w600 : FontWeight.w500,
                  color: hasQuery ? LegalTheme.ink : const Color(0xFF9AA4B2),
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: LegalTheme.muted),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.search_rounded,
                    size: 18, color: LegalTheme.muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// The leading scope control — which register column the text matches. Echoes
/// the CNR field's in-field label, but tappable, in accent, with a caret.
class _ScopeToken extends StatelessWidget {
  final SearchScope scope;
  final VoidCallback onTap;
  const _ScopeToken({required this.scope, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 7, 8),
        decoration: BoxDecoration(
          color: LegalTheme.blueBg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_scopeLabel(scope),
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: LegalTheme.blue)),
            const SizedBox(width: 1),
            const Icon(Icons.expand_more_rounded,
                size: 15, color: LegalTheme.blue),
          ],
        ),
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FiltersButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? LegalTheme.blue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? LegalTheme.blue : const Color(0xFFDCE2EB)),
          boxShadow: [
            BoxShadow(
              color: (active ? LegalTheme.blue : LegalTheme.ink)
                  .withValues(alpha: active ? 0.22 : 0.06),
              blurRadius: active ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded,
                size: 18, color: active ? Colors.white : LegalTheme.ink),
            if (active) ...[
              const SizedBox(width: 7),
              Text('$count',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Removable chips for the filters currently narrowing the search. Tapping one
/// drops just that filter and re-runs.
class _ActiveFilters extends StatelessWidget {
  final SearchCriteria criteria;
  final void Function(SearchCriteria) onChanged;
  const _ActiveFilters({required this.criteria, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final s in criteria.statuses)
        _RemovableChip(
          label: _statusLabel(s),
          onRemove: () => onChanged(criteria.copyWith(
              statuses: {...criteria.statuses}..remove(s))),
        ),
      if (criteria.hasHearingRange)
        _RemovableChip(
          label: 'Hearing ${_rangeLabel(criteria.hearingFrom, criteria.hearingTo)}',
          onRemove: () =>
              onChanged(criteria.copyWith(hearingFrom: null, hearingTo: null)),
        ),
      if (criteria.sortField != SortField.relevance)
        _RemovableChip(
          label:
              '${_sortLabel(criteria.sortField)} ${criteria.sortDescending ? '↓' : '↑'}',
          onRemove: () =>
              onChanged(criteria.copyWith(sortField: SortField.relevance)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 7, 8, 7),
        decoration: BoxDecoration(
            color: LegalTheme.blueBg, borderRadius: BorderRadius.circular(9)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: LegalTheme.blue)),
            const SizedBox(width: 5),
            const Icon(Icons.close_rounded, size: 13, color: LegalTheme.blue),
          ],
        ),
      ),
    );
  }
}

// --- Search console (blurred pop-out) -----------------------------------------

/// Opens the search console over the blurred board: an editable, autofocused
/// field, inline scope, recent queries and an explicit Search button. The board
/// behind it is the work; the console is a transient surface laid on top, so it
/// reads as "the register, brought into focus" rather than another panel.
///
/// It takes plain callbacks (not the bloc) so it works pushed on the root
/// navigator, like the filters sheet — [onSubmit] runs against the screen's bloc.
void _showSearchConsole(
  BuildContext context, {
  required SearchCriteria initial,
  required List<String> recents,
  required void Function(SearchCriteria) onSubmit,
}) {
  final reduceMotion = MediaQuery.of(context).disableAnimations;
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) =>
        _SearchConsole(initial: initial, recents: recents, onSubmit: onSubmit),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      child: child,
    ),
  );
}

class _SearchConsole extends StatefulWidget {
  final SearchCriteria initial;
  final List<String> recents;
  final void Function(SearchCriteria) onSubmit;

  const _SearchConsole({
    required this.initial,
    required this.recents,
    required this.onSubmit,
  });

  @override
  State<_SearchConsole> createState() => _SearchConsoleState();
}

class _SearchConsoleState extends State<_SearchConsole> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial.text);
  late SearchCriteria _criteria = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() => Navigator.of(context).pop();

  /// Closes the console, then runs the search on the host bloc with [text].
  void _run(String text) {
    Navigator.of(context).pop();
    widget.onSubmit(_criteria.copyWith(text: text));
  }

  void _openFilters() {
    _showSearchFilters(
      context,
      _criteria.copyWith(text: _controller.text),
      (next) => setState(() => _criteria = next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss, // tap the blurred board to close
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: LegalTheme.ink.withValues(alpha: 0.18),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: GestureDetector(
                    onTap: () {}, // absorb taps on the card itself
                    // showGeneralDialog gives no Material ancestor; the card's
                    // TextField needs one. Transparent so the blur shows through.
                    child: Material(
                      type: MaterialType.transparency,
                      child: _card(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _label = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
      color: LegalTheme.muted);

  Widget _card() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration:
          LegalTheme.cardDecoration(radius: 22, blur: 30, opacity: 0.16, dy: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, size: 17, color: LegalTheme.ink),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Search the register',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: LegalTheme.ink)),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: LegalTheme.field,
                      borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.close_rounded,
                      size: 17, color: LegalTheme.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Find a case by party, advocate or judge — no CNR needed.',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: LegalTheme.muted)),
          const SizedBox(height: 14),
          _field(),
          const SizedBox(height: 16),
          const Text('SEARCH BY', style: _label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in SearchScope.values)
                _ChoiceChip(
                  label: _scopeLabel(s),
                  selected: _criteria.scope == s,
                  onTap: () =>
                      setState(() => _criteria = _criteria.copyWith(scope: s)),
                ),
            ],
          ),
          if (widget.recents.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('RECENT', style: _label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in widget.recents)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _run(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                          color: LegalTheme.field,
                          borderRadius: BorderRadius.circular(9)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded,
                              size: 13, color: LegalTheme.muted),
                          const SizedBox(width: 5),
                          Text(q,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: LegalTheme.ink)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              _FiltersButton(count: _criteria.filterCount, onTap: _openFilters),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _run(_controller.text),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: LegalTheme.blue,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: LegalTheme.blue.withValues(alpha: 0.30),
                            blurRadius: 18,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Search',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LegalTheme.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LegalTheme.page),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: LegalTheme.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: LegalTheme.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: _scopeHint(_criteria.scope),
                hintStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9AA4B2)),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _controller.clear,
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: LegalTheme.muted),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Filters sheet ------------------------------------------------------------

void _showSearchFilters(
  BuildContext context,
  SearchCriteria current,
  void Function(SearchCriteria) onApply,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchFiltersSheet(initial: current, onApply: onApply),
  );
}

class _SearchFiltersSheet extends StatefulWidget {
  final SearchCriteria initial;
  final void Function(SearchCriteria) onApply;
  const _SearchFiltersSheet({required this.initial, required this.onApply});

  @override
  State<_SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<_SearchFiltersSheet> {
  late Set<String> _statuses = {...widget.initial.statuses};
  late DateTime? _from = widget.initial.hearingFrom;
  late DateTime? _to = widget.initial.hearingTo;
  late SortField _sort = widget.initial.sortField;
  late bool _desc = widget.initial.sortDescending;

  bool get _anyActive =>
      _statuses.isNotEmpty ||
      _from != null ||
      _to != null ||
      _sort != SortField.relevance;

  void _toggleStatus(String s) => setState(
      () => _statuses.contains(s) ? _statuses.remove(s) : _statuses.add(s));

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: LegalTheme.blue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  void _clearAll() => setState(() {
        _statuses = {};
        _from = null;
        _to = null;
        _sort = SortField.relevance;
        _desc = true;
      });

  void _apply() {
    Navigator.pop(context);
    widget.onApply(widget.initial.copyWith(
      statuses: _statuses,
      hearingFrom: _from,
      hearingTo: _to,
      sortField: _sort,
      sortDescending: _desc,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: LegalTheme.sheetDecoration,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegalModals.grabber(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Filters',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (_anyActive)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _clearAll,
                      child: const Text('Clear all',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: LegalTheme.blue)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _FilterSection(
                label: 'Status',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in const ['PENDING', 'DISPOSED'])
                      _ChoiceChip(
                        label: _statusLabel(s),
                        selected: _statuses.contains(s),
                        onTap: () => _toggleStatus(s),
                      ),
                  ],
                ),
              ),
              _FilterSection(
                label: 'Next hearing',
                child: _DateRangeRow(
                  from: _from,
                  to: _to,
                  onTap: _pickRange,
                  onClear: (_from != null || _to != null)
                      ? () => setState(() {
                            _from = null;
                            _to = null;
                          })
                      : null,
                ),
              ),
              _FilterSection(
                label: 'Sort by',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in SortField.values)
                          _ChoiceChip(
                            label: _sortLabel(f),
                            selected: _sort == f,
                            onTap: () => setState(() => _sort = f),
                          ),
                      ],
                    ),
                    if (_sort != SortField.relevance) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _ChoiceChip(
                            label: 'Newest first',
                            selected: _desc,
                            onTap: () => setState(() => _desc = true),
                          ),
                          _ChoiceChip(
                            label: 'Oldest first',
                            selected: !_desc,
                            onTap: () => setState(() => _desc = false),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _apply,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LegalTheme.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Show results',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: LegalTheme.muted)),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 22),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? LegalTheme.blue : LegalTheme.field,
          borderRadius: BorderRadius.circular(11),
          border:
              Border.all(color: selected ? LegalTheme.blue : LegalTheme.page),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : LegalTheme.ink)),
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DateRangeRow({
    required this.from,
    required this.to,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final set = from != null || to != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: LegalTheme.field,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LegalTheme.page),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, size: 17, color: LegalTheme.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_rangeLabel(from, to),
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: set ? LegalTheme.ink : LegalTheme.muted)),
            ),
            if (set && onClear != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 17, color: LegalTheme.muted),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: LegalTheme.muted),
          ],
        ),
      ),
    );
  }
}

// --- Search vocabulary --------------------------------------------------------

String _scopeLabel(SearchScope s) => switch (s) {
      SearchScope.all => 'Anywhere',
      SearchScope.advocate => 'Advocate',
      SearchScope.judge => 'Judge',
      SearchScope.party => 'Party',
    };

String _scopeHint(SearchScope s) => switch (s) {
      SearchScope.all => 'Search the whole register',
      SearchScope.advocate => 'Advocate name',
      SearchScope.judge => 'Judge name',
      SearchScope.party => 'Party name',
    };

String _statusLabel(String code) {
  final c = code.toUpperCase();
  if (c == 'PENDING') return 'Pending';
  if (c == 'DISPOSED') return 'Disposed';
  return code.isEmpty ? code : code[0] + code.substring(1).toLowerCase();
}

String _sortLabel(SortField f) => switch (f) {
      SortField.relevance => 'Best match',
      SortField.nextHearing => 'Next hearing',
      SortField.filingDate => 'Filing date',
      SortField.decisionDate => 'Decision date',
    };

String _shortDate(DateTime d) => '${d.day} ${LegalTheme.monthAbbr[d.month - 1]}';

String _rangeLabel(DateTime? from, DateTime? to) {
  if (from != null && to != null) {
    return '${_shortDate(from)} – ${_shortDate(to)}';
  }
  if (from != null) return 'from ${_shortDate(from)}';
  if (to != null) return 'until ${_shortDate(to)}';
  return 'Any date';
}

/// Today's cause list — the idle resting state beneath the search field.
class _BoardSection extends StatelessWidget {
  const _BoardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loading =
        context.select((EcourtsBloc b) => b.state.causeListLoading);
    final list = context.select((EcourtsBloc b) => b.state.causeList);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_note_rounded,
                size: 16, color: LegalTheme.ink),
            const SizedBox(width: 7),
            const Text('Today on the board',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: LegalTheme.ink)),
            const Spacer(),
            if (!loading)
              Text('${list.length} listed',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: LegalTheme.muted)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Matters scheduled across tracked courts. Tap to pull one up.',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: LegalTheme.muted)),
        const SizedBox(height: 12),
        if (loading)
          const _CauseListSkeleton()
        else
          ...list.map((e) {
            // A listing with a CNR opens its full live record. One without a CNR
            // hasn't been assigned a record number yet, so there's nothing to
            // pull — tapping it shows the basic details the cause list carries.
            final hasCnr = Cnr.isValid(e.cnr);
            return _CauseRow(
              entry: e,
              hasCnr: hasCnr,
              onTap: () => hasCnr
                  ? context.read<EcourtsBloc>().add(EcourtsLookupRequested(e.cnr))
                  : _showListingSheet(context, e),
            );
          }),
      ],
    );
  }
}

/// Header for the search states: the magnifier, a status line, and a count.
class _SearchHeader extends StatelessWidget {
  final String query;
  final String trailing;
  const _SearchHeader({required this.query, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.manage_search_rounded,
                size: 16, color: LegalTheme.ink),
            const SizedBox(width: 7),
            const Text('Search results',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: LegalTheme.ink)),
            const Spacer(),
            if (trailing.isNotEmpty)
              Text(trailing,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: LegalTheme.muted)),
          ],
        ),
        const SizedBox(height: 4),
        query.trim().isEmpty
            ? const Text('Cases matching your filters',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: LegalTheme.muted))
            : Text.rich(
                TextSpan(
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: LegalTheme.muted),
                  children: [
                    const TextSpan(text: 'Cases matching '),
                    TextSpan(
                        text: '“$query”',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: LegalTheme.ink)),
                  ],
                ),
              ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SearchBusy extends StatelessWidget {
  final String query;
  const _SearchBusy({required this.query, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchHeader(query: query, trailing: 'Searching…'),
        const _CauseListSkeleton(),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final hits = context.select((EcourtsBloc b) => b.state.searchHits);
    final query =
        context.select((EcourtsBloc b) => b.state.searchCriteria.text);

    if (hits.isEmpty) return _SearchEmpty(query: query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchHeader(
            query: query,
            trailing: '${hits.length} ${hits.length == 1 ? 'case' : 'cases'}'),
        ...hits.map((h) => _SearchResultRow(hit: h, query: query)),
      ],
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  final CaseSearchHit hit;
  final String query;
  const _SearchResultRow({required this.hit, required this.query});

  void _open(BuildContext context) {
    if (Cnr.isValid(hit.cnr)) {
      context.read<EcourtsBloc>().add(EcourtsLookupRequested(hit.cnr));
    } else {
      LegalModals.snack(
          context, "This result has no record number on file yet.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final disposed = hit.caseStatus.toLowerCase().contains('dispos');
    final hasCnr = Cnr.isValid(hit.cnr);
    final court = hit.court.trim();
    final caseNo = hit.caseNumber.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration:
            LegalTheme.cardDecoration(radius: 16, blur: 12, opacity: 0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlighted(hit.title.isEmpty ? 'Unknown parties' : hit.title,
                      query),
                  const SizedBox(height: 3),
                  if (court.isNotEmpty)
                    Text(court,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: LegalTheme.muted)),
                  if (caseNo.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(caseNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: _mono,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: LegalTheme.muted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hit.caseStatus.trim().isNotEmpty)
                  _StatusPill(
                      label: disposed ? 'Disposed' : 'Pending',
                      color: disposed ? _green : _amber),
                const SizedBox(height: 8),
                Icon(hasCnr ? Icons.chevron_right : Icons.info_outline_rounded,
                    color: LegalTheme.muted, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Renders [title] with each run of [query] lit in the accent — so the reader
  /// sees at a glance why this case matched. Case-insensitive, whole-query.
  Widget _highlighted(String title, String query) {
    const base = TextStyle(
        fontSize: 13.5, fontWeight: FontWeight.w700, color: LegalTheme.ink);
    const mark = TextStyle(
        fontSize: 13.5, fontWeight: FontWeight.w800, color: LegalTheme.blue);

    final q = query.trim();
    final spans = <TextSpan>[];
    if (q.isEmpty) {
      spans.add(TextSpan(text: title));
    } else {
      final lower = title.toLowerCase();
      final needle = q.toLowerCase();
      var i = 0;
      while (i < title.length) {
        final at = lower.indexOf(needle, i);
        if (at < 0) {
          spans.add(TextSpan(text: title.substring(i)));
          break;
        }
        if (at > i) spans.add(TextSpan(text: title.substring(i, at)));
        spans.add(TextSpan(
            text: title.substring(at, at + needle.length), style: mark));
        i = at + needle.length;
      }
    }

    return Text.rich(TextSpan(style: base, children: spans),
        maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

class _SearchEmpty extends StatelessWidget {
  final String query;
  const _SearchEmpty({required this.query});

  @override
  Widget build(BuildContext context) {
    return _SearchNotice(
      icon: Icons.search_off_rounded,
      title: 'No matches',
      body: query.trim().isEmpty
          ? 'No cases match these filters. Widen the date range or status, '
              'or add a name to search.'
          : 'No cases on file match “$query”. '
              'Check the spelling, change the scope, or look it up by CNR above.',
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.select((EcourtsBloc b) => b.state.searchError);
    return _SearchNotice(
      icon: Icons.cloud_off_rounded,
      title: 'Search failed',
      body: message.isEmpty
          ? 'Something went wrong. Try again in a moment.'
          : message,
    );
  }
}

/// Shared empty/error card for the search states.
class _SearchNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SearchNotice(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration:
          LegalTheme.cardDecoration(radius: 20, blur: 14, opacity: 0.05),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: LegalTheme.muted, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: LegalTheme.ink)),
          const SizedBox(height: 5),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: LegalTheme.muted)),
        ],
      ),
    );
  }
}

class _CauseRow extends StatelessWidget {
  final CauseListEntry entry;
  final VoidCallback onTap;

  /// Whether this listing carries a CNR. CNR rows pull the full record; rows
  /// without one open the basic-details sheet instead.
  final bool hasCnr;

  const _CauseRow({
    required this.entry,
    required this.onTap,
    this.hasCnr = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: LegalTheme.cardDecoration(radius: 16, blur: 12, opacity: 0.05),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.ink)),
                  const SizedBox(height: 2),
                  Text('Item ${entry.serial} · ${entry.purpose}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: LegalTheme.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasCnr)
              const Icon(Icons.chevron_right, color: LegalTheme.muted, size: 18)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                    color: _amberBg,
                    borderRadius: BorderRadius.circular(7)),
                child: const Text('No CNR',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: _amber)),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Listing without a CNR ----------------------------------------------------

/// Opens the basic details a cause-list listing carries. Used for listings the
/// registry hasn't assigned a CNR to yet: there's no record to pull, so rather
/// than guess one we show what the cause list holds and say a CNR is pending.
void _showListingSheet(BuildContext context, CauseListEntry entry) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ListingSheet(entry: entry),
  );
}

class _ListingSheet extends StatelessWidget {
  final CauseListEntry entry;
  const _ListingSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final title = entry.title.trim();
    // Only the fields the cause list actually carries — no blank rows.
    final facts = <(String, String, bool)>[
      if (entry.serial > 0) ('Item', '${entry.serial}', false),
      if (entry.caseNumber.trim().isNotEmpty)
        ('Case no.', entry.caseNumber.trim(), true),
      if (entry.purpose.trim().isNotEmpty)
        ('Purpose', entry.purpose.trim(), false),
      if (entry.court.trim().isNotEmpty) ('Court', entry.court.trim(), false),
      if (entry.judge.trim().isNotEmpty) ('Before', entry.judge.trim(), false),
      if (entry.time.trim().isNotEmpty) ('Listed', entry.time.trim(), false),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: LegalTheme.sheetDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegalModals.grabber(),
          const SizedBox(height: 16),
          const Text('LISTING',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: LegalTheme.muted)),
          const SizedBox(height: 6),
          Text(title.isEmpty ? 'Untitled listing' : title,
              style: const TextStyle(
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: LegalTheme.ink)),
          const SizedBox(height: 16),
          const _PendingCnrPlate(),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              decoration: LegalTheme.cardDecoration(
                  radius: 18, blur: 14, opacity: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < facts.length; i++)
                    _FactRow(
                      label: facts[i].$1,
                      value: facts[i].$2,
                      mono: facts[i].$3,
                      last: i == facts.length - 1,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: LegalTheme.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Once the court assigns a CNR, you can pull the full case '
                    'record here.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: LegalTheme.muted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The signature [_CnrPlate], inverted: where a resolved case shows its dark
/// CNR plate, a pending listing shows the same plate with the record number
/// ghosted out and stamped "Not assigned".
class _PendingCnrPlate extends StatelessWidget {
  const _PendingCnrPlate();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      decoration: BoxDecoration(
        color: LegalTheme.ink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: LegalTheme.ink.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CNR',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFF6B7689))),
              Spacer(),
              _StatusPill(label: 'Not assigned', color: _amber, onDark: true),
            ],
          ),
          SizedBox(height: 14),
          // The three CNR blocks (6-6-4 chars), ghosted to read as "pending".
          Row(
            children: [
              _GhostBlock(width: 86),
              _GhostDot(),
              _GhostBlock(width: 86),
              _GhostDot(),
              _GhostBlock(width: 58),
            ],
          ),
          SizedBox(height: 14),
          Text(
              "This matter is on the board, but the court hasn't issued a record "
              'number for it yet.',
              style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A94A6))),
        ],
      ),
    );
  }
}

class _GhostBlock extends StatelessWidget {
  final double width;
  const _GhostBlock({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3A4356)),
      ),
    );
  }
}

class _GhostDot extends StatelessWidget {
  const _GhostDot();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('·',
            style: TextStyle(
                color: Color(0xFF4C5566),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      );
}

// --- Result -------------------------------------------------------------------

class _CaseResult extends StatelessWidget {
  final EcourtsCase result;
  const _CaseResult({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CnrPlate(result: result),
        const SizedBox(height: 16),
        _PartiesBlock(result: result),
        const SizedBox(height: 16),
        _FactsCard(result: result),
        if (result.fir != null) ...[
          const SizedBox(height: 16),
          _FirCard(fir: result.fir!),
        ],
        if (result.acts.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionLabel('Acts & sections'),
          const SizedBox(height: 10),
          _ActsWrap(acts: result.acts),
        ],
        if (result.history.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionLabel('Case history'),
          const SizedBox(height: 10),
          _HistoryTimeline(history: result.history),
        ],
        if (result.orders.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionLabel('Orders & judgments'),
          const SizedBox(height: 10),
          ...result.orders.map((o) => _OrderRow(order: o)),
        ],
        const SizedBox(height: 20),
        _AddToCasesButton(result: result),
      ],
    );
  }
}

/// The signature: the CNR on a single dark "official record" plate — the one
/// bold moment on an otherwise light screen.
class _CnrPlate extends StatelessWidget {
  final EcourtsCase result;
  const _CnrPlate({required this.result});

  @override
  Widget build(BuildContext context) {
    final disposed = result.isDisposed;
    final segments = Cnr.segments(result.cnr);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      decoration: BoxDecoration(
        color: LegalTheme.ink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: LegalTheme.ink.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('CNR',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFF6B7689))),
              const Spacer(),
              _StatusPill(
                  label: disposed ? 'Disposed' : 'Pending',
                  color: disposed ? _green : _amber,
                  onDark: true),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·',
                        style: TextStyle(
                            color: Color(0xFF4C5566),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                Text(segments[i],
                    style: const TextStyle(
                        fontFamily: _mono,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(result.title,
              style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 3),
          Text('${result.caseType} · ${result.source}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8A94A6))),
          const SizedBox(height: 14),
          Row(
            children: [
              const _Dot(color: _green),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Synced ${_fmtSync(result.fetchedAt)}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7689))),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: result.cnr));
                  LegalModals.snack(context, 'CNR copied');
                },
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 13, color: Color(0xFF8A94A6)),
                    SizedBox(width: 5),
                    Text('Copy',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A94A6))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool onDark;
  const _StatusPill(
      {required this.label, required this.color, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: color)),
        ],
      ),
    );
  }
}

class _PartiesBlock extends StatelessWidget {
  final EcourtsCase result;
  const _PartiesBlock({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LegalTheme.cardDecoration(radius: 18, blur: 14, opacity: 0.06),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _PartyRow(
              role: 'Petitioner',
              color: LegalTheme.blue,
              party: result.petitioners.isEmpty
                  ? const EcourtsParty(name: 'Unknown')
                  : result.petitioners.first),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: Divider(height: 1, color: Color(0xFFEDF0F4))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('v.',
                      style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.muted)),
                ),
                Expanded(child: Divider(height: 1, color: Color(0xFFEDF0F4))),
              ],
            ),
          ),
          _PartyRow(
              role: 'Respondent',
              color: _amber,
              party: result.respondents.isEmpty
                  ? const EcourtsParty(name: 'Unknown')
                  : result.respondents.first),
        ],
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  final String role;
  final Color color;
  final EcourtsParty party;
  const _PartyRow(
      {required this.role, required this.color, required this.party});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 34,
          margin: const EdgeInsets.only(top: 2, right: 12),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: color)),
              const SizedBox(height: 3),
              Text(party.name,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: LegalTheme.ink)),
              if (party.advocate != null) ...[
                const SizedBox(height: 2),
                Text(party.advocate!,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: LegalTheme.muted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FactsCard extends StatelessWidget {
  final EcourtsCase result;
  const _FactsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final s = result.status;
    return Container(
      decoration: LegalTheme.cardDecoration(radius: 18, blur: 14, opacity: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          _FactRow(
              label: result.isDisposed ? 'Decided' : 'Next hearing',
              value: _fmtDate(result.isDisposed
                  ? s.decisionDate
                  : s.nextHearingDate),
              mono: true,
              highlight: !result.isDisposed),
          _FactRow(label: 'Stage', value: s.stage),
          if (result.isDisposed && s.natureOfDisposal != null)
            _FactRow(label: 'Disposal', value: s.natureOfDisposal!),
          _FactRow(
              label: 'Filing no.', value: result.filingNumber, mono: true),
          _FactRow(label: 'Filed', value: _fmtDate(result.filingDate), mono: true),
          _FactRow(
              label: 'Registration no.',
              value: result.registrationNumber,
              mono: true),
          _FactRow(
              label: 'Registered',
              value: _fmtDate(result.registrationDate),
              mono: true),
          _FactRow(label: 'Court', value: s.courtNumberAndJudge, last: true),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool highlight;
  final bool last;
  const _FactRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.highlight = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F3F7), width: 1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LegalTheme.muted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: mono ? _mono : null,
                    fontSize: mono ? 12.5 : 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: highlight ? LegalTheme.blue : LegalTheme.ink)),
          ),
        ],
      ),
    );
  }
}

class _FirCard extends StatelessWidget {
  final EcourtsFir fir;
  const _FirCard({required this.fir});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amberBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6E2CE)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.gavel_rounded, size: 18, color: _amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FIR ${fir.firNumber}/${fir.year}',
                    style: const TextStyle(
                        fontFamily: _mono,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: LegalTheme.ink)),
                const SizedBox(height: 2),
                Text(fir.policeStation,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: LegalTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActsWrap extends StatelessWidget {
  final List<EcourtsAct> acts;
  const _ActsWrap({required this.acts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: acts
          .map((a) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: LegalTheme.cardDecoration(
                    radius: 11, blur: 8, opacity: 0.04),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.act,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LegalTheme.ink)),
                    const SizedBox(width: 7),
                    Text(a.section,
                        style: const TextStyle(
                            fontFamily: _mono,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: LegalTheme.blue)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final List<EcourtsHearing> history;
  const _HistoryTimeline({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LegalTheme.cardDecoration(radius: 18, blur: 14, opacity: 0.06),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++)
            _HistoryRow(entry: history[i], last: i == history.length - 1),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final EcourtsHearing entry;
  final bool last;
  const _HistoryRow({required this.entry, required this.last});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                    color: last ? LegalTheme.muted : LegalTheme.blue,
                    shape: BoxShape.circle),
              ),
              if (!last)
                const Expanded(
                  child: VerticalDivider(
                      width: 1, thickness: 1.5, color: Color(0xFFE6EAF0)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 11, bottom: last ? 11 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fmtDate(entry.businessOnDate),
                      style: const TextStyle(
                          fontFamily: _mono,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.ink)),
                  const SizedBox(height: 2),
                  Text(entry.purpose,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: LegalTheme.ink)),
                  const SizedBox(height: 1),
                  Text(
                      entry.nextDate == null
                          ? entry.judge
                          : 'Adjourned to ${_fmtDate(entry.nextDate)} · ${entry.judge}',
                      style: const TextStyle(
                          fontSize: 11, color: LegalTheme.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final EcourtsOrder order;
  const _OrderRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: LegalTheme.cardDecoration(radius: 16, blur: 12, opacity: 0.05),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: LegalTheme.blueBg,
                borderRadius: BorderRadius.circular(10)),
            child: Text('#${order.number}',
                style: const TextStyle(
                    fontFamily: _mono,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: LegalTheme.blue)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: LegalTheme.ink)),
                const SizedBox(height: 2),
                Text(_fmtDate(order.date),
                    style: const TextStyle(
                        fontFamily: _mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LegalTheme.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(7)),
            child: const Text('PDF',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: LegalTheme.muted)),
          ),
        ],
      ),
    );
  }
}

class _AddToCasesButton extends StatelessWidget {
  final EcourtsCase result;
  const _AddToCasesButton({required this.result});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final cases = context.read<CaseBloc>().state.cases;
        if (cases.any((c) => c.cnr == result.cnr)) {
          LegalModals.snack(context, 'This case is already in your cases');
          return;
        }
        final type = _appType(result.caseType);
        final nextDate = result.nextHearingDate;
        context.read<CaseBloc>().add(CaseCreated(
              name: result.title,
              number: result.registrationNumber,
              court: result.source,
              type: type,
              folders: LegalTheme.foldersForType(type),
              cnr: result.cnr,
              hearing: nextDate != null ? Case.formatHearing(nextDate) : null,
            ));
        final nav = context.read<NavigationBloc>();
        nav.add(const SourceSelected(null));
        nav.add(const TabChanged('cases'));
        LegalModals.snack(context, '${result.title} added to your cases');
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LegalTheme.ink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 19),
            SizedBox(width: 8),
            Text('Add to my cases',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// --- Empty / error ------------------------------------------------------------

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select((EcourtsBloc b) => b.state.status);
    final queryCnr = context.select((EcourtsBloc b) => b.state.queryCnr);
    final message = context.select((EcourtsBloc b) => b.state.message);

    final (icon, title, body) = switch (status) {
      EcourtsStatus.notFound => (
          Icons.search_off_rounded,
          'No case found',
          Cnr.isValid(queryCnr)
              ? 'No record carries ${Cnr.format(queryCnr)}. Double-check the 16 characters.'
              : 'No case matched ${queryCnr.isEmpty ? 'that listing' : queryCnr}. It may not be published yet.'
        ),
      EcourtsStatus.invalid => (
          Icons.error_outline_rounded,
          'That CNR looks off',
          message ?? 'A CNR is exactly 16 letters and digits.'
        ),
      _ => (
          Icons.cloud_off_rounded,
          'Lookup failed',
          message ?? 'Something went wrong. Try again in a moment.'
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: LegalTheme.cardDecoration(radius: 20, blur: 14, opacity: 0.05),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(17)),
            child: Icon(icon, color: LegalTheme.muted, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: LegalTheme.ink)),
          const SizedBox(height: 5),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: LegalTheme.muted)),
        ],
      ),
    );
  }
}

// --- Skeletons ----------------------------------------------------------------

class _ResultSkeleton extends StatelessWidget {
  const _ResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 132,
          decoration: BoxDecoration(
              color: LegalTheme.ink.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20)),
        ),
        const SizedBox(height: 16),
        _bar(86),
        const SizedBox(height: 16),
        _bar(176),
      ],
    );
  }

  Widget _bar(double height) => Container(
        height: height,
        decoration: LegalTheme.cardDecoration(
            radius: 18, blur: 14, opacity: 0.05, color: Colors.white),
      );
}

class _CauseListSkeleton extends StatelessWidget {
  const _CauseListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: LegalTheme.cardDecoration(
              radius: 16, blur: 12, opacity: 0.04, color: Colors.white),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: LegalTheme.ink));
  }
}
