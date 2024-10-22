import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'home/home_controller.dart';
import 'home/home_view.dart';
import 'services/nnyy_data.dart';
import 'services/save_strategy.dart';
import 'services/data_store.dart';

bool unsupported = kIsWeb || (Platform.isWindows || Platform.isLinux);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    DataStore.customPath = (await getApplicationSupportDirectory()).path;
  }
  HomeController.i;
  NnyyData.init();
  SaveStrategy.init();
  if (kIsWeb) await BrowserContextMenu.disableContextMenu();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nnyy',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellowAccent.shade400,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      }),
      navigatorObservers: [SaveStrategy.navigatorChangeObserver],
      home: const HomeView(),
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return IconButtonTheme(
            data: IconButtonThemeData(
                style: IconButton.styleFrom().copyWith(
                    overlayColor: WidgetStateProperty.resolveWith(
              (set) => set.contains(WidgetState.focused) &&
                      !set.contains(WidgetState.selected) &&
                      !set.contains(WidgetState.hovered)
                  ? colorScheme.onSecondaryFixedVariant
                  : null,
            ))),
            child: child!);
      },
    );
  }
}
