import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/desktop_state.dart';
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

  runApp(DexLauncherApp(desktopState: desktopState));
}

class DexLauncherApp extends StatelessWidget {
  final DesktopState desktopState;

  const DexLauncherApp({super.key, required this.desktopState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: desktopState,
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
