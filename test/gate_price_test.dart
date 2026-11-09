import 'package:flutter_test/flutter_test.dart';
import 'package:sylverscreen_scan/api/gate_api.dart';

void main() {
  test('keeps individual ticket price distinct from reservation total', () {
    final result = GateScanResult.fromJson({
      'status': 'already_used', 'message': 'Billet déjà utilisé',
      'ticketType': 'Ticket + Popcorn', 'ticketAmount': 4000,
      'ticketCurrency': 'XAF', 'totalAmount': 14000,
    });
    expect(result.ticketType, 'Ticket + Popcorn');
    expect(result.ticketAmount, 4000);
    expect(result.ticketCurrency, 'XAF');
    expect(result.totalAmount, 14000);
  });
  test('does not substitute reservation total when legacy price is missing', () {
    final result = GateScanResult.fromJson({'status': 'accepted', 'totalAmount': 14000});
    expect(result.ticketAmount, isNull);
    expect(result.ticketType, isNull);
  });
  test('preserves a free individual ticket', () {
    final result = GateScanResult.fromJson({'status': 'accepted', 'ticketAmount': 0, 'totalAmount': 3000});
    expect(result.ticketAmount, 0);
  });
}
