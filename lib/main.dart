import 'dart:io';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(KusotschnitsaApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class KusotschnitsaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кусочница',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.orange),
      ),
      home: LoginScreen(),
    );
  }
}