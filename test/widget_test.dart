import 'package:flutter_test/flutter_test.dart';
import 'package:myway_plus/main.dart';

void main() {
  testWidgets('home screen renders the journey planner and sample departures', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyWayApp());

    expect(find.text('MYWAY'), findsOneWidget);
    expect(find.text('PLAN A JOURNEY'), findsOneWidget);
    expect(find.text('Nearby departures'), findsOneWidget);
    expect(find.text('FIND ROUTE'), findsOneWidget);
    expect(find.text('GLOBAL DISCOVERY'), findsOneWidget);
  });
}
