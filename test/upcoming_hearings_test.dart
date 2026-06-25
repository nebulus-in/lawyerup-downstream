import 'package:flutter_test/flutter_test.dart';
import 'package:unsettled/models/legal_models.dart';

Case c(String name, String hearing) => Case(
    id: name.hashCode,
    name: name,
    number: '',
    court: '',
    type: 'CIVIL',
    docs: 0,
    hearing: hearing);

String onDay(int offset) =>
    Case.formatHearing(legalToday.add(Duration(days: offset)));

void main() {
  test('formatHearing round-trips a real year', () {
    final dt = DateTime(2027, 3, 9);
    expect(Case.formatHearing(dt), 'Mar 9, 2027');
    expect(Case.parseHearing('Mar 9, 2027'), dt);
  });

  test('parseHearing falls back to current year for legacy strings', () {
    expect(Case.parseHearing('Jun 28'), DateTime(legalToday.year, 6, 28));
  });

  test('upcoming shows today-or-later, all days, sorted, drops past', () {
    final cases = [
      c('Past', onDay(-5)),        // before today -> excluded
      c('Today', onDay(0)),        // today -> included
      c('Soon', onDay(2)),
      c('Mid', onDay(4)),
      c('Far', onDay(30)),         // 4th distinct day -> old maxDays:2 dropped it
      c('Unscheduled', '-'),       // no date -> excluded
    ];
    final got = Case.upcomingHearings(cases).map((e) => e.name).toList();
    expect(got, ['Today', 'Soon', 'Mid', 'Far']);
  });
}
