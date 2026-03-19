import 'package:flutter_test/flutter_test.dart';
import 'package:dex_launcher/models/desktop_state.dart';
import 'package:dex_launcher/services/system_status_service.dart';
import 'package:dex_launcher/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    final state = DesktopState();
    final systemStatus = SystemStatusService();
    await tester.pumpWidget(DexLauncherApp(
      desktopState: state,
      systemStatus: systemStatus,
    ));
    expect(find.byType(DexLauncherApp), findsOneWidget);
  });
}
