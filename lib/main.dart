import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:lvluo/page/eyeball.dart';
import 'package:lvluo/src/rust/api/net_monitor.dart';
import 'package:lvluo/src/rust/api/simple.dart';
import 'package:lvluo/src/rust/frb_generated.dart';
import 'package:lvluo/utils/config.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  await RustLib.init();

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    // size: Size(25, 100),
    // maximumSize: Size(50, 100),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

    windowManager.waitUntilReadyToShow(windowOptions, () async {

    await windowManager.show();
    await windowManager.focus();
    await windowManager.setAsFrameless();
    await windowManager.undock();


  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.light;

  @override
  void initState() {
    sharedConfigManager.addListener(configListen);
    super.initState();
  }

  @override
  void dispose() {
    sharedConfigManager.removeListener(configListen);
    super.dispose();
  }

  void configListen() {
    themeMode = sharedConfig.themeMode;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final virtualWindowFrameBuilder = VirtualWindowFrameInit();
    final botToastBuilder = BotToastInit();

    // return EyeballPage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      builder: (context, child) {
        child = virtualWindowFrameBuilder(context, child);
        child = botToastBuilder(context, child);
        return child;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
      home: const EyeballPage(),
    );
  }
}

class MyApp1 extends StatelessWidget {
  const MyApp1({super.key});

  @override
  Widget build(BuildContext context) {

    var e = getNetDevStats();
    print("stats: ${e[0].devId} ${e[0].rxBytes} ${e[0].txBytes} ${e[0].statValid}");

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
              'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`'),
        ),
      ),
    );
  }
}
