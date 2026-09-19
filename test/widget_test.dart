import 'package:flutter_test/flutter_test.dart';
import 'package:pipedata_pro/main.dart';

void main() {
  testWidgets('App launches and shows the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PipingWorkstationApp());

    // Large title on the home screen.
    expect(find.text('Piping Data Pro'), findsOneWidget);
    // Spot-check the first category card renders (first group, so it's
    // guaranteed to be within the initial viewport without scrolling).
    expect(find.text('Pipes'), findsOneWidget);
  });
}
