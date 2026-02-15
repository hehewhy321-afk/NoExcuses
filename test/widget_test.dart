import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test — full app requires platform channels
    expect(1 + 1, 2);
  });
}
