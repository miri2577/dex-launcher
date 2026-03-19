import 'package:flutter_test/flutter_test.dart';
import 'package:dex_launcher/models/desktop_state.dart';
import 'package:dex_launcher/services/system_status_service.dart';
import 'package:dex_launcher/windows/window_manager.dart';
import 'package:dex_launcher/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    final state = DesktopState();
    final systemStatus = SystemStatusService();
    final windowManager = WindowManager();
    await tester.pumpWidget(DexLauncherApp(
      desktopState: state,
      systemStatus: systemStatus,
      windowManager: windowManager,
    ));
    expect(find.byType(DexLauncherApp), findsOneWidget);
  });
}
