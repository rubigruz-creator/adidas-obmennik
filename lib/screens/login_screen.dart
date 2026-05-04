import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'files_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.register(_phoneController.text, _passwordController.text);
      // ApiService.register возвращает Map<String, dynamic>
      if (data['status'] == 'success') {
        _showMessage('✅ Регистрация успешна! Теперь войдите', isError: false);
        setState(() => _isRegistering = false);
        _passwordController.clear();
      } else {
        _showMessage(data['message'] ?? 'Ошибка регистрации');
      }
    } catch (e) {
      _showMessage('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.login(_phoneController.text, _passwordController.text);
      if (data['status'] == 'success') {
        // Сохраняем данные пользователя
        await AuthService.saveToken(data['api_token']);
        await AuthService.saveUserNickname(data['user']['nickname']);
        await AuthService.saveUserId(data['user']['id']);
        await AuthService.saveIsAdmin(data['user']['is_admin'] ?? 0);
        
        _showMessage('✅ Добро пожаловать, ${data['user']['nickname']}!', isError: false);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FilesScreen()),
        );
      } else {
        _showMessage(data['message'] ?? 'Ошибка входа');
      }
    } catch (e) {
      _showMessage('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepOrange.shade900, Colors.black],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_special, size: 80, color: Colors.orange),
                SizedBox(height: 20),
                Text(
                  '🍖 Кусочница',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),
                
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Телефон (+71234567890)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white24,
                  ),
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 16),
                
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white24,
                  ),
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 24),
                
                if (_isLoading)
                  CircularProgressIndicator()
                else if (_isRegistering)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('ЗАРЕГИСТРИРОВАТЬСЯ'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isRegistering = false),
                        child: Text('Уже есть аккаунт? Войти'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('ВОЙТИ'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isRegistering = true),
                        child: Text('Нет аккаунта? Зарегистрироваться'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}