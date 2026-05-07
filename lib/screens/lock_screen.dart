import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:lottie/lottie.dart';

class LockScreen extends StatefulWidget {
  final String storedPinHash;
  const LockScreen({Key? key, required this.storedPinHash}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  String? _errorText;

  void _unlock() {
    final entered = _pinController.text.trim();
    if (entered.length < 4) {
      setState(() => _errorText = 'Минимум 4 цифры');
      return;
    }
    final hash = sha256.convert(utf8.encode(entered)).toString();
    if (hash == widget.storedPinHash) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorText = 'Неверный PIN');
      _pinController.clear();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Анимированный логотип
              Lottie.asset(
                'assets/animations/adidas.json',
                width: 150,
                height: 75,
                repeat: true,
                animate: true,
              ),
              const SizedBox(height: 24),
              const Text(
                'Введите PIN-код',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterStyle: const TextStyle(color: Colors.white30),
                  errorText: _errorText,
                  errorStyle: const TextStyle(color: Colors.red),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _unlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 48),
                ),
                child: const Text('Разблокировать'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Выйти',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}