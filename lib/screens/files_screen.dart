import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/file_pill.dart';
import 'login_screen.dart';

class FilesScreen extends StatefulWidget {
  @override
  _FilesScreenState createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<dynamic> _files = [];
  bool _isLoading = true;
  String _apiToken = '';
  int _currentUserId = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();
    final isAdmin = await AuthService.getIsAdmin();
    
    if (token == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }
    
    setState(() {
      _apiToken = token;
      _currentUserId = userId ?? 0;
      _isAdmin = isAdmin == 1;
    });
    
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await ApiService.getFiles(_apiToken);
      setState(() => _files = files);
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showVisibilityDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Тип файла'),
        content: Text('Сделать файл доступным для всех?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Личный'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Общий'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _uploadFile(File file, String fileName, bool isPublic) async {
    final success = await ApiService.uploadFile(_apiToken, file, fileName, isPublic: isPublic);
    if (success) {
      _loadFiles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $fileName загружен!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка загрузки')),
      );
    }
  }

  Future<void> _pickAnyFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final file = File(result.files.first.path!);
    final isPublic = await _showVisibilityDialog();
    await _uploadFile(file, result.files.first.name, isPublic);
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final isPublic = await _showVisibilityDialog();
      await _uploadFile(File(pickedFile.path), pickedFile.name, isPublic);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final isPublic = await _showVisibilityDialog();
      await _uploadFile(File(pickedFile.path), pickedFile.name, isPublic);
    }
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    final success = await ApiService.downloadFile(_apiToken, fileId, fileName);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📁 Файл сохранён в Downloads/$fileName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка скачивания')),
      );
    }
  }

  Future<void> _deleteFile(int fileId, String fileName, int ownerId) async {
    final canDelete = _isAdmin || ownerId == _currentUserId;
    
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Нет прав на удаление этого файла')),
      );
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить файл?'),
        content: Text('Вы уверены, что хотите удалить "$fileName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await ApiService.deleteFile(_apiToken, fileId);
      if (success) {
        _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Файл удалён')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка удаления')),
        );
      }
    }
  }

  Future<void> _renameFile(dynamic file) async {
    final ownerId = file['user_id'];
    final canRename = _isAdmin || ownerId == _currentUserId;
    
    if (!canRename) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нет прав на переименование')),
      );
      return;
    }
    
    final controller = TextEditingController(text: file['original_name']);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переименовать файл'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Новое имя',
            hintText: 'Введите новое имя файла',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Переименовать'),
          ),
        ],
      ),
    );
    
    if (newName != null && newName.isNotEmpty && newName != file['original_name']) {
      final success = await ApiService.renameFile(_apiToken, file['id'], newName);
      if (success) {
        _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл переименован в "$newName"')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка переименования')),
        );
      }
    }
  }


  void _showFileMenu(dynamic file) {
    final ownerId = file['user_id'];
    final canDelete = _isAdmin || ownerId == _currentUserId;
    final isPublic = file['is_public'] == 1;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(file['original_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Размер: ${file['size_mb']} MB'),
            Text('Тип: ${file['file_type']}'),
            Text('Хозяин: ${file['owner_nickname']}'),
            Text('Дата: ${file['upload_date']}'),
            SizedBox(height: 8),


            InkWell(
              onTap: () async {
                final success = await ApiService.toggleVisibility(_apiToken, file['id']);
                if (success) {
                  Navigator.pop(context);
                  _loadFiles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isPublic ? '🔒 Стал личным' : '🌍 Стал общим')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPublic ? Icons.public : Icons.lock,
                      size: 18,
                      color: isPublic ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      isPublic ? 'Общий файл (нажми сменить)' : 'Личный файл (нажми сменить)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPublic ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ), 

            



            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _downloadFile(file['id'], file['original_name']);
              },
              icon: Icon(Icons.download),
              label: Text('Скачать'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _renameFile(file);
              },
              icon: Icon(Icons.edit, color: Colors.blue),
              label: Text('Переименовать'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100),
            ),
            if (canDelete) ...[
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteFile(file['id'], file['original_name'], ownerId);
                },
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Удалить', style: TextStyle(color: Colors.red)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🍖 Кусочница'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'file') _pickAnyFile();
              if (value == 'gallery') _pickImageFromGallery();
              if (value == 'camera') _takePhoto();
            },
            icon: Icon(Icons.add),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'file', child: Text('📎 Любой файл')),
              PopupMenuItem(value: 'gallery', child: Text('🖼️ Фото из галереи')),
              PopupMenuItem(value: 'camera', child: Text('📷 Фото с камеры')),
            ],
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadFiles),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(child: Text('Нет файлов. Нажми + чтобы загрузить'))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: _files.length,
                  itemBuilder: (context, index) => FilePill(
                    file: _files[index],
                    index: index,
                    onTap: () => _showFileMenu(_files[index]),
                  ),
                ),
    );
  }
}