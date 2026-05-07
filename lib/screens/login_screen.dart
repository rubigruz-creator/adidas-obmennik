import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'files_screen.dart';
import '../services/websocket_service.dart';
import '../utils/app_config.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _phone = '';
  String _password = '';
  String _nickname = '';
  String _fullName = '';
  String _position = '';

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      dynamic response;
      if (_isLogin) {
        response = await ApiService.login(_phone, _password);
        if (response['status'] == 'success') {
          await AuthService.saveToken(response['api_token']);
          await AuthService.saveUserId(response['user']['id']);
          await AuthService.saveUserNickname(response['user']['nickname']);
          await AuthService.saveIsAdmin(response['user']['is_admin']);

          WebSocketService().connect(response['api_token']);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FilesScreen()),
          );
        } else {
          _showError('Ошибка входа');
        }
      } else {
        response = await ApiService.register(
          _phone,
          _password,
          _nickname,
          _fullName,
          _position,
        );
        if (response['status'] == 'success') {
          setState(() {
            _isLogin = true;
            _password = '';
            _nickname = '';
            _fullName = '';
            _position = '';
          });
          _showError('Регистрация успешна! Теперь войдите', isError: false);
        } else {
          _showError('Ошибка регистрации');
        }
      }
    } catch (e) {
      _showError('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип
              Lottie.asset(
                'assets/animations/adidas.json',
                width: 200,
                height: 100,
                repeat: true,
              ),
              SizedBox(height: 16),
              Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                AppConfig.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),
              Card(
                elevation: 0,
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLogin ? 'Вход' : 'Регистрация',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Телефон',
                            prefixIcon: Icon(Icons.phone, color: Colors.red),
                          ),
                          onSaved: (val) => _phone = val!,
                          validator: (val) => val!.isEmpty ? 'Введите телефон' : null,
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            prefixIcon: Icon(Icons.lock, color: Colors.red),
                          ),
                          obscureText: true,
                          onSaved: (val) => _password = val!,
                          validator: (val) => val!.isEmpty ? 'Введите пароль' : null,
                          style: TextStyle(color: Colors.white),
                        ),
                        if (!_isLogin) ...[
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Никнейм',
                              prefixIcon: Icon(Icons.person, color: Colors.red),
                            ),
                            onSaved: (val) => _nickname = val!,
                            validator: (val) => val!.isEmpty ? 'Введите никнейм' : null,
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Полное имя',
                              prefixIcon: Icon(Icons.badge, color: Colors.red),
                            ),
                            onSaved: (val) => _fullName = val!,
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Должность',
                              prefixIcon: Icon(Icons.work, color: Colors.red),
                            ),
                            onSaved: (val) => _position = val!,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                        SizedBox(height: 24),
                        if (_isLoading)
                          CircularProgressIndicator(color: Colors.red)
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Войти' : 'Зарегистрироваться',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? 'Нет аккаунта? Зарегистрироваться'
                                : 'Уже есть аккаунт? Войти',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}