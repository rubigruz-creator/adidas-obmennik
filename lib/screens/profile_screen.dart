import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'audit_log_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String apiToken;
  
  const ProfileScreen({Key? key, required this.apiToken}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _profile = {};
  
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _positionController = TextEditingController();

  final _storage = const FlutterSecureStorage();
  String? _currentPinHash;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPinStatus();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadPinStatus() async {
    _currentPinHash = await _storage.read(key: 'pin_hash');
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getProfile(widget.apiToken);
      setState(() {
        _profile = profile;
        _nicknameController.text = profile['nickname'] ?? '';
        _fullNameController.text = profile['full_name'] ?? '';
        _positionController.text = profile['position'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final updates = <String, dynamic>{};
    if (_nicknameController.text.trim() != _profile['nickname']) {
      updates['nickname'] = _nicknameController.text.trim();
    }
    if (_fullNameController.text.trim() != (_profile['full_name'] ?? '')) {
      updates['full_name'] = _fullNameController.text.trim();
    }
    if (_positionController.text.trim() != (_profile['position'] ?? '')) {
      updates['position'] = _positionController.text.trim();
    }
    
    if (updates.isEmpty) {
      setState(() => _isSaving = false);
      if (mounted) Navigator.pop(context, false);
      return;
    }
    
    try {
      final updatedProfile = await ApiService.updateProfile(
        widget.apiToken,
        nickname: updates['nickname'],
        fullName: updates['full_name'],
        position: updates['position'],
      );
      
      if (updatedProfile['nickname'] != null) {
        await AuthService.saveUserNickname(updatedProfile['nickname']);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Профиль обновлён')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  // Диалог установки/изменения PIN-кода
  void _showPinDialog({bool changing = false}) async {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(changing ? 'Изменить PIN-код' : 'Установить PIN-код'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (changing && _currentPinHash != null)
                TextField(
                  controller: oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Текущий PIN',
                    hintText: 'Введите текущий PIN',
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: changing ? 'Новый PIN' : 'PIN-код',
                  hintText: 'От 4 до 6 цифр',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Подтверждение',
                  hintText: 'Повторите PIN-код',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'old': oldPinController.text,
                'new': newPinController.text,
                'confirm': confirmController.text,
              });
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final newPin = result['new'] ?? '';
    final confirm = result['confirm'] ?? '';
    final oldPin = result['old'] ?? '';

    // Валидация
    if (newPin.length < 4 || newPin.length > 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN должен содержать от 4 до 6 цифр')),
        );
      }
      return;
    }

    if (newPin != confirm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN-коды не совпадают')),
        );
      }
      return;
    }

    // Проверка старого PIN при изменении
    if (changing && _currentPinHash != null) {
      final oldHash = sha256.convert(utf8.encode(oldPin)).toString();
      if (oldHash != _currentPinHash) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Неверный текущий PIN')),
          );
        }
        return;
      }
    }

    // Сохраняем хеш нового PIN
    final newHash = sha256.convert(utf8.encode(newPin)).toString();
    await _storage.write(key: 'pin_hash', value: newHash);
    setState(() => _currentPinHash = newHash);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(changing ? '✅ PIN-код изменён' : '✅ PIN-код установлен')),
      );
    }
  }

  // Удаление PIN-кода
  Future<void> _deletePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить PIN-код?'),
        content: const Text('Приложение больше не будет запрашивать PIN при возврате из фона.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.delete(key: 'pin_hash');
      setState(() => _currentPinHash = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ PIN-код удалён')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        centerTitle: true,
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Сохранить',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Карточка профиля
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Телефон',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile['phone'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _nicknameController,
                              decoration: const InputDecoration(
                                labelText: 'Никнейм',
                                hintText: 'Как вас будут видеть другие',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите никнейм';
                                }
                                if (value.trim().length < 3) {
                                  return 'Никнейм должен быть не менее 3 символов';
                                }
                                if (value.trim().length > 50) {
                                  return 'Никнейм не более 50 символов';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Полное имя',
                                hintText: 'Иван Иванов',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _positionController,
                              decoration: const InputDecoration(
                                labelText: 'Должность',
                                hintText: 'Менеджер проектов',
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                            ),
                            
                                    if (_profile['is_admin'] == 1) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, color: Colors.amber[800]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'У вас права администратора',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AuditLogScreen(
                                          apiToken: widget.apiToken,
                                          user: _profile,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.history),
                                  label: const Text('История действий'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],                  
                          
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Блок безопасности: PIN-код
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Безопасность',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_currentPinHash == null)
                              ListTile(
                                leading: const Icon(Icons.lock_outline),
                                title: const Text('Установить PIN-код'),
                                subtitle: const Text('Дополнительная защита при возврате в приложение'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () => _showPinDialog(),
                              )
                            else ...[
                              ListTile(
                                leading: const Icon(Icons.lock),
                                title: const Text('Изменить PIN-код'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () => _showPinDialog(changing: true),
                              ),
                              ListTile(
                                leading: const Icon(Icons.lock_open),
                                title: const Text('Удалить PIN-код'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: _deletePin,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Кнопка сохранения
                    if (_isSaving)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Сохранить изменения'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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