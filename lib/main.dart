import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'screens/lock_screen.dart';
import 'utils/app_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  NotificationService.onNotificationTap = (response) {
    print('Notification tapped, payload: ${response.payload}');
  };

  HttpOverrides.global = MyHttpOverrides();
  runApp(AdidasExchangerApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class AdidasExchangerApp extends StatefulWidget {
  @override
  State<AdidasExchangerApp> createState() => _AdidasExchangerAppState();
}

class _AdidasExchangerAppState extends State<AdidasExchangerApp>
    with WidgetsBindingObserver {
  bool _lockScreenShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // Проверяем, нужен ли PIN-код
      final storage = FlutterSecureStorage();
      final pinHash = await storage.read(key: 'pin_hash');
      if (pinHash != null && pinHash.isNotEmpty && !_lockScreenShown) {
        _lockScreenShown = true;
        final unlocked = await showDialog<bool>(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (context) => LockScreen(storedPinHash: pinHash),
        );
        _lockScreenShown = false;
        if (unlocked != true) {
          // Если не разблокирован – выходим из приложения (не идеально, но можно и просто вернуться)
          // Лучше просто выбросить на экран входа? Для простоты просто ничего не делаем.
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFEF3340), // красный Adidas
          brightness: Brightness.dark,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Color(0xFFEF3340),
          surface: Color(0xFF121212),
          onSurface: Color(0xFFE0E0E0),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFEF3340),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[900],
        ),
      ),
      home: SplashScreen(),
    );
  }
}
