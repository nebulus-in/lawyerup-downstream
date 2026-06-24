import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../widgets/legal_modals.dart';
import '../../bloc/blocs.dart';
import '../../../models/legal_models.dart';

/// The Calendar tab: a litigator's-eye view of the docket.
///
/// Opens with a navigable month grid, then the month's cause list — 
/// the days a matter is listed, laid out on a docket spine.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  // Expanded range for a more flexible docket view
  static final DateTime _min = DateTime(2020, 1);
  static final DateTime _max = DateTime(2035, 12);
  static final DateTime _currentMonth =
      DateTime(LegalTheme.today.year, LegalTheme.today.month);

  DateTime _month = _currentMonth;

  /// Direction of the last month change (-1 back, 1 forward), driving the
  /// slide of the swap animation.
  int _dir = 0;

  bool get _canPrev => _month.isAfter(_min);
  bool get _canNext => _month.isBefore(_max);
  bool get _isCurrentMonth => _month == _currentMonth;

  void _changeMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isBefore(_min) || next.isAfter(_max)) return;
    setState(() {
      _dir = delta;
      _month = next;
    });
  }

  void _jumpToMonth(DateTime target) {
    if (target == _month) return;
    setState(() {
      _dir = target.isBefore(_month) ? -1 : 1;
      _month = target;
    });
  }

  void _jumpToToday() {
    if (_isCurrentMonth) return;
    setState(() {
      _dir = _currentMonth.isBefore(_month) ? -1 : 1;
      _month = _currentMonth;
    });
  }

  /// Brings [date]'s month into view and opens its day sheet.
  void _openDate(DateTime date) {
    final target = DateTime(date.year, date.month);
    if (target != _month && !target.isBefore(_min) && !target.isAfter(_max)) {
      setState(() {
        _dir = target.isBefore(_month) ? -1 : 1;
        _month = target;
      });
    }
    context.read<NavigationBloc>().add(DateSelected(date));
  }

  @override
  Widget build(BuildContext context) {
    final cases = context.select((CaseBloc bloc) => bloc.state.cases);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ListView(
      key: const ValueKey('calendar'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _MonthHeader(
          month: _month,
          canPrev: _canPrev,
          canNext: _canNext,
          showToday: !_isCurrentMonth,
          onPrev: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
          onToday: _jumpToToday,
          onTitleTap: () => LegalModals.showMonthYearPicker(
            context,
            initialDate: _month,
            minDate: _min,
            maxDate: _max,
            onSelected: _jumpToMonth,
          ),
        ),
        const SizedBox(height: 20),
        _MonthSwap(
          monthKey: _month.millisecondsSinceEpoch,
          direction: _dir,
          animate: !reduceMotion,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthGrid(month: _month, cases: cases, onTapDay: _openDate),
              const SizedBox(height: 22),
              _CauseList(month: _month, cases: cases, onTapDay: _openDate),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final bool canPrev;
  final bool canNext;
  final bool showToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onTitleTap;

  const _MonthHeader({
    required this.month,
    required this.canPrev,
    required this.canNext,
    required this.showToday,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTitleTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LegalTheme.monthName(month.month),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: LegalTheme.ink,
                          height: 1.05),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, 
                      color: LegalTheme.muted, size: 22),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${month.year}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: LegalTheme.muted,
                      letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
        if (showToday) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: LegalTheme.blueBg,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Today',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: LegalTheme.blue)),
            ),
          ),
          const SizedBox(width: 10),
        ],
        _NavButton(icon: Icons.chevron_left, enabled: canPrev, onTap: onPrev),
        const SizedBox(width: 8),
        _NavButton(icon: Icons.chevron_right, enabled: canNext, onTap: onNext),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 38,
        height: 38,
        decoration: enabled
            ? LegalTheme.cardDecoration(radius: 12, opacity: 0.05, blur: 12, dy: 3)
            : BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(12)),
        child: Icon(icon,
            size: 22,
            color: enabled ? LegalTheme.ink : const Color(0xFFC4CBD6)),
      ),
    );
  }
}

/// A docket-stamp date tile: weekday over a heavy day numeral, in a matter's
/// colour. Reused by the cause-list spine.
class _DocketTile extends StatelessWidget {
  final DateTime date;
  final Color color;
  final Color bg;
  final bool solid;

  const _DocketTile({
    required this.date,
    required this.color,
    required this.bg,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = solid ? Colors.white : color;
    return Container(
      width: 50,
      height: 52,
      decoration: BoxDecoration(
          color: solid ? color : bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(LegalTheme.weekdayShort(date.weekday),
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: fg)),
          Text('${date.day}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: fg)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month grid
// ---------------------------------------------------------------------------

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final List<Case> cases;
  final void Function(DateTime date) onTapDay;

  const _MonthGrid(
      {required this.month, required this.cases, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    const headers = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    // Sunday-first, matching the header row.
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = month.year == LegalTheme.today.year &&
        month.month == LegalTheme.today.month;

    final hearingsByDay = <int, List<Case>>{};
    for (final c in cases) {
      final d = c.hearingDate;
      if (d != null && d.year == month.year && d.month == month.month) {
        hearingsByDay.putIfAbsent(d.day, () => []).add(c);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: LegalTheme.cardDecoration(radius: 20, blur: 16, opacity: 0.05),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < headers.length; i++)
                Expanded(
                  child: Center(
                    child: Text(headers[i],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: (i == 0 || i == 6)
                                ? const Color(0xFFC2C9D4)
                                : LegalTheme.muted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = index - firstWeekday + 1;
              final weekday = (firstWeekday + day - 1) % 7;
              final isWeekend = weekday == 0 || weekday == 6;
              final isToday = isCurrentMonth && day == LegalTheme.today.day;
              final dayCases = hearingsByDay[day] ?? const [];

              return _DayCell(
                day: day,
                isToday: isToday,
                isWeekend: isWeekend,
                cases: dayCases,
                onTap: () => onTapDay(DateTime(month.year, month.month, day)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isWeekend;
  final List<Case> cases;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isWeekend,
    required this.cases,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHearing = cases.isNotEmpty;
    final numberColor = isToday
        ? Colors.white
        : (isWeekend ? const Color(0xFFB6BECB) : LegalTheme.ink);

    final dotColors = <Color>[
      for (final c in cases.take(3))
        isToday ? Colors.white : LegalTheme.getCaseColor(c.type),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? LegalTheme.blue : LegalTheme.field,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        (isToday || hasHearing) ? FontWeight.w800 : FontWeight.w600,
                    color: numberColor)),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: hasHearing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < dotColors.length; i++) ...[
                          if (i > 0) const SizedBox(width: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: dotColors[i], shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cause list (the month's docket spine)
// ---------------------------------------------------------------------------

class _CauseList extends StatelessWidget {
  final DateTime month;
  final List<Case> cases;
  final void Function(DateTime date) onTapDay;

  const _CauseList(
      {required this.month, required this.cases, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    final byDay = <int, List<Case>>{};
    for (final c in cases) {
      final d = c.hearingDate;
      if (d != null && d.year == month.year && d.month == month.month) {
        byDay.putIfAbsent(d.day, () => []).add(c);
      }
    }
    final days = byDay.keys.toList()..sort();
    final total = byDay.values.fold<int>(0, (n, list) => n + list.length);
    final isCurrentMonth = month.year == LegalTheme.today.year &&
        month.month == LegalTheme.today.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Cause list',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LegalTheme.ink)),
            const SizedBox(width: 8),
            Text(LegalTheme.monthName(month.month),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LegalTheme.muted)),
            const Spacer(),
            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: LegalTheme.blueBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$total ${total == 1 ? 'hearing' : 'hearings'}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: LegalTheme.blue)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (days.isEmpty)
          _EmptyMonth(month: month)
        else
          for (var i = 0; i < days.length; i++)
            _CauseDay(
              date: DateTime(month.year, month.month, days[i]),
              cases: byDay[days[i]]!,
              isLast: i == days.length - 1,
              isPast: isCurrentMonth && days[i] < LegalTheme.today.day,
              isToday: isCurrentMonth && days[i] == LegalTheme.today.day,
              onTapDate: onTapDay,
            ),
      ],
    );
  }
}

class _CauseDay extends StatelessWidget {
  final DateTime date;
  final List<Case> cases;
  final bool isLast;
  final bool isPast;
  final bool isToday;
  final void Function(DateTime date) onTapDate;

  const _CauseDay({
    required this.date,
    required this.cases,
    required this.isLast,
    required this.isPast,
    required this.isToday,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    // The day node is tinted by its first matter; the spine stays neutral.
    final nodeColor = LegalTheme.getCaseColor(cases.first.type);
    final nodeBg = LegalTheme.getCaseBg(cases.first.type);

    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTapDate(date),
                  child: _DocketTile(
                      date: date,
                      color: nodeColor,
                      bg: nodeBg,
                      solid: isToday),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: LegalTheme.page,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                children: [
                  for (var i = 0; i < cases.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _CauseCaseRow(c: cases[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return isPast ? Opacity(opacity: 0.5, child: row) : row;
  }
}

class _CauseCaseRow extends StatelessWidget {
  final Case c;
  const _CauseCaseRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final color = LegalTheme.getCaseColor(c.type);
    final bg = LegalTheme.getCaseBg(c.type);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final nav = context.read<NavigationBloc>();
        nav.add(const TabChanged('cases'));
        nav.add(CaseSelected(c.id));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LegalTheme.page),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LegalTheme.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${c.number} · ${c.court}',
                      style: const TextStyle(
                          fontSize: 11.5, color: LegalTheme.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(6)),
              child: Text(c.type,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  final DateTime month;
  const _EmptyMonth({required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: LegalTheme.cardDecoration(radius: 20, blur: 14, opacity: 0.04),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.gavel_rounded,
                color: LegalTheme.muted, size: 22),
          ),
          const SizedBox(height: 12),
          Text('No hearings listed in ${LegalTheme.monthName(month.month)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LegalTheme.ink)),
          const SizedBox(height: 4),
          const Text('Tap any day above to list a case for that date.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: LegalTheme.muted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month change transition
// ---------------------------------------------------------------------------

/// Cross-fades and slides the grid + cause list when the month changes,
/// in the direction of travel. A no-op when motion is reduced.
class _MonthSwap extends StatelessWidget {
  final int monthKey;
  final int direction;
  final bool animate;
  final Widget child;

  const _MonthSwap({
    required this.monthKey,
    required this.direction,
    required this.animate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: Offset(0.05 * direction, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: KeyedSubtree(key: ValueKey(monthKey), child: child),
    );
  }
}
