import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(KusotschnitsaApp());
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