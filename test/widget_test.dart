import 'package:flutter_test/flutter_test.dart';
import 'package:pipedata_pro/main.dart';

void main() {
  testWidgets('App launches and shows the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PipingWorkstationApp());
    await tester.pump();

    // CupertinoSliverNavigationBar can keep more than one 'Piping Data Pro'
    // Text in the tree at once (large title + the collapsed persistent
    // title it animates in), so this checks presence, not an exact count.
    expect(find.text('Piping Data Pro'), findsWidgets);
    // Spot-check the first category card renders (first group, so it's
    // guaranteed to be within the initial viewport without scrolling).
    expect(find.text('Pipes'), findsWidgets);
  });
}
