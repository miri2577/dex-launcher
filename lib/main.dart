import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/desktop_state.dart';
import 'services/system_status_service.dart';
import 'windows/window_manager.dart';
import 'desktop/desktop_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Vollbild, keine System-UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Landscape erzwingen (TV ist immer Landscape)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // State initialisieren
  final desktopState = DesktopState();
  await desktopState.init();

  final systemStatus = SystemStatusService();
  await systemStatus.initMouseCheck();
  systemStatus.startPolling();

  final windowManager = WindowManager();

  // Restore window layout only if no auto-start tools are configured
  if (desktopState.autoStartTools.isEmpty) {
    await windowManager.restoreLayout();
  }

  runApp(DexLauncherApp(
    desktopState: desktopState,
    systemStatus: systemStatus,
    windowManager: windowManager,
  ));
}

class DexLauncherApp extends StatelessWidget {
  final DesktopState desktopState;
  final SystemStatusService systemStatus;
  final WindowManager windowManager;

  const DexLauncherApp({
    super.key,
    required this.desktopState,
    required this.systemStatus,
    required this.windowManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: desktopState),
        ChangeNotifierProvider.value(value: systemStatus),
        ChangeNotifierProvider.value(value: windowManager),
      ],
      child: Shortcuts(
        // Android TV Remote: "Select" Button als Tap registrieren
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        },
        child: Consumer<DesktopState>(
          builder: (context, ds, child) => MaterialApp(
            title: 'DeX Launcher',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              colorSchemeSeed: ds.accentColor,
              useMaterial3: true,
            ),
            home: const DesktopShell(),
          ),
        ),
      ),
    );
  }
}
