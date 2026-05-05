import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _positionController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки профиля: $e')),
      );
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
      Navigator.pop(context, false); // Не обновлять главный экран
      return;
    }
    
    try {
      final updatedProfile = await ApiService.updateProfile(
        widget.apiToken,
        nickname: updates['nickname'],
        fullName: updates['full_name'],
        position: updates['position'],
      );
      
      // Обновляем сохранённые данные в SharedPreferences
      if (updatedProfile['nickname'] != null) {
        await AuthService.saveUserNickname(updatedProfile['nickname']);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Профиль обновлён')),
      );
      Navigator.pop(context, true); // Нужно обновить главный экран
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мой профиль'),
        centerTitle: true,
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Телефон',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _profile['phone'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Divider(height: 24),
                            TextFormField(
                              controller: _nicknameController,
                              decoration: InputDecoration(
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
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Полное имя',
                                hintText: 'Иван Иванов',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _positionController,
                              decoration: InputDecoration(
                                labelText: 'Должность',
                                hintText: 'Менеджер проектов',
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                            ),
                            if (_profile['is_admin'] == 1) ...[
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings, color: Colors.amber[800]),
                                    SizedBox(width: 12),
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
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_isSaving)
                      Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: Icon(Icons.save),
                          label: Text('Сохранить изменения'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
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