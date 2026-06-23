import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/blocs.dart';
import '../../../models/legal_models.dart';
import 'legal_modals.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.select((CaseBloc bloc) => bloc.state.cases);

    return ListView(
      key: const ValueKey('calendar'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('June 2026',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => LegalModals.snack(
                      context, 'June 2026 is the only month in this preview.'),
                  child: _calNavIcon(Icons.chevron_left),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => LegalModals.snack(
                      context, 'June 2026 is the only month in this preview.'),
                  child: _calNavIcon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CalendarCard(cases: cases),
        const SizedBox(height: 12),
        const Center(
          child: Text('Tap any day to add or view a hearing',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w500, color: LegalTheme.muted)),
        ),
        const SizedBox(height: 20),
        const Text('Hearings this month',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...cases.map((c) => _MiniCaseItem(c: c)),
      ],
    );
  }

  Widget _calNavIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: LegalTheme.ink),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final List<Case> cases;
  const _CalendarCard({required this.cases});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LegalTheme.cardDecoration(radius: 20, blur: 16),
      child: Column(
        children: [
          _CalendarGrid(cases: cases),
          const SizedBox(height: 16),
          const Row(
            children: [
              _LegendChip(fill: LegalTheme.blue, label: 'Hearing day'),
              SizedBox(width: 18),
              _LegendChip(fill: null, label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color? fill;
  final String label;
  const _LegendChip({required this.fill, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill ?? Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: fill == null ? Border.all(color: LegalTheme.blue, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: LegalTheme.muted)),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<Case> cases;
  const _CalendarGrid({required this.cases});

  @override
  Widget build(BuildContext context) {
    const headers = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final firstWeekday = DateTime(2026, 6, 1).weekday % 7;
    const daysInMonth = 30;
    const today = 22;

    final hearingDays = <int>{};
    for (final c in cases) {
      final date = c.hearingDate;
      if (date != null && date.month == 6) hearingDays.add(date.day);
    }

    return Column(
      children: [
        Row(
          children: headers
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: LegalTheme.muted)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, crossAxisSpacing: 7, mainAxisSpacing: 7),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) return const SizedBox();
            final day = index - firstWeekday + 1;
            final hasHearing = hearingDays.contains(day);
            final isToday = day == today;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  context.read<NavigationBloc>().add(DateSelected(DateTime(2026, 6, day))),
              child: Container(
                decoration: BoxDecoration(
                  color: hasHearing
                      ? LegalTheme.blue
                      : (isToday ? const Color(0xFFEAF1FE) : LegalTheme.field),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !hasHearing
                      ? Border.all(color: LegalTheme.blue, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasHearing || isToday
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: hasHearing
                                ? Colors.white
                                : (isToday ? LegalTheme.blue : LegalTheme.ink))),
                    if (hasHearing)
                      Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MiniCaseItem extends StatelessWidget {
  final Case c;
  const _MiniCaseItem({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: LegalTheme.cardDecoration(radius: 12, blur: 8, opacity: 0.04, dy: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Text(c.hearing,
                  style: const TextStyle(fontSize: 11, color: LegalTheme.muted)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: LegalTheme.getCaseBg(c.type), borderRadius: BorderRadius.circular(6)),
            child: Text(c.type,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: LegalTheme.getCaseColor(c.type))),
          ),
        ],
      ),
    );
  }
}
