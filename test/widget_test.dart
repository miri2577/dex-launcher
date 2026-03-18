import 'package:flutter_test/flutter_test.dart';
import 'package:dex_launcher/models/desktop_state.dart';
import 'package:dex_launcher/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    final state = DesktopState();
    await tester.pumpWidget(DexLauncherApp(desktopState: state));
    expect(find.byType(DexLauncherApp), findsOneWidget);
  });
}
