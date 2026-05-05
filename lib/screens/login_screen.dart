import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'files_screen.dart';

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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade800, Colors.brown.shade700],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? '🍖 Вход' : '📝 Регистрация',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Телефон',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _phone = val!,
                        validator: (val) => val!.isEmpty ? 'Введите телефон' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSaved: (val) => _password = val!,
                        validator: (val) => val!.isEmpty ? 'Введите пароль' : null,
                      ),
                      if (!_isLogin) ...[
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Никнейм',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => _nickname = val!,
                          validator: (val) => val!.isEmpty ? 'Введите никнейм' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Полное имя',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => _fullName = val!,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Должность',
                            prefixIcon: Icon(Icons.work),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => _position = val!,
                        ),
                      ],
                      SizedBox(height: 24),
                      if (_isLoading)
                        CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.orange.shade800,
                          ),
                          child: Text(
                            _isLogin ? 'Войти' : 'Зарегистрироваться',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'Нет аккаунта? Зарегистрироваться'
                              : 'Уже есть аккаунт? Войти',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}