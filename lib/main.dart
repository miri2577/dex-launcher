import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/desktop_state.dart';
import 'services/system_status_service.dart';
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
  await systemStatus.initMouseCheck(); // Sofort-Check vor UI
  systemStatus.startPolling();

  runApp(DexLauncherApp(desktopState: desktopState, systemStatus: systemStatus));
}

class DexLauncherApp extends StatelessWidget {
  final DesktopState desktopState;
  final SystemStatusService systemStatus;

  const DexLauncherApp({
    super.key,
    required this.desktopState,
    required this.systemStatus,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: desktopState),
        ChangeNotifierProvider.value(value: systemStatus),
      ],
      child: Shortcuts(
        // Android TV Remote: "Select" Button als Tap registrieren
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        },
        child: MaterialApp(
          title: 'DeX Launcher',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF1F4068),
            useMaterial3: true,
          ),
          home: const DesktopShell(),
        ),
      ),
    );
  }
}
