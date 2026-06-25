import 'package:flutter_test/flutter_test.dart';
import 'package:unsettled/services/ecourts/http_ecourts_api.dart';

void main() {
  test('read cache stays fresh under 12h, expires after', () {
    final now = DateTime(2026, 6, 25, 12);
    expect(HttpEcourtsApi.fresh(now.subtract(const Duration(hours: 11, minutes: 59)), now), isTrue);
    expect(HttpEcourtsApi.fresh(now.subtract(const Duration(hours: 12, minutes: 1)), now), isFalse);
  });
}
