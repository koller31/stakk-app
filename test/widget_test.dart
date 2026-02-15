import 'package:flutter_test/flutter_test.dart';

import 'package:idswipe/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IDswipeApp());
    expect(find.text('IDswipe'), findsOneWidget);
  });
}
