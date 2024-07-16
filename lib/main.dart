import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelfRouter;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Запрос разрешения на отключение оптимизаций батареи
  bool batteryOptimizationDisabled = await _requestBatteryOptimizationDisable();

  if (batteryOptimizationDisabled) {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Background Server",
      notificationText: "Your server is running in the background",
      notificationImportance: AndroidNotificationImportance.Default,
      enableWifiLock: true,
    );

    bool hasPermissions =
        await FlutterBackground.initialize(androidConfig: androidConfig);

    if (hasPermissions) {
      FlutterBackground.enableBackgroundExecution();
    }

    runApp(const MyApp());
    startServer();
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('HTTP Server Example')),
        body: const Center(child: Text('Server is running...')),
      ),
    );
  }
}

Future<void> startServer() async {
  final router = shelfRouter.Router();

  router.get('/hello', (Request request) {
    return Response.ok('Hello, World!');
  });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server running on port ${server.port}');
}

Future<bool> _requestBatteryOptimizationDisable() async {
  var status = await Permission.ignoreBatteryOptimizations.request();
  if (status.isGranted) {
    return true;
  } else {
    // Направить пользователя на экран настроек для отключения оптимизаций батареи
    bool openedSettings = await openAppSettings();
    if (openedSettings) {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } else {
      return false;
    }
  }
}
