import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/file_pill.dart';
import '../widgets/folder_pill.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class FilesScreen extends StatefulWidget {
  @override
  _FilesScreenState createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<dynamic> _folders = [];
  List<dynamic> _files = [];
  bool _isLoading = true;
  String _apiToken = '';
  int _currentUserId = 0;
  bool _isAdmin = false;
  int? _currentFolderId;
  List<Map<String, dynamic>> _folderPath = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoad() async {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId();
    final isAdmin = await AuthService.getIsAdmin();

    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _apiToken = token;
        _currentUserId = userId ?? 0;
        _isAdmin = isAdmin == 1;
      });
    }

    await _loadContent();
  }

  Future<void> _loadContent() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final content = await ApiService.getFolderContent(
        _apiToken,
        folderId: _currentFolderId,
        search: _searchQuery,
      );
      
      if (mounted) {
        setState(() {
          _folders = content['folders'];
          _files = content['files'];
        });
      }
      
      if (_currentFolderId != null) {
        await _loadFolderPath();
      } else {
        if (mounted) setState(() => _folderPath = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFolderPath() async {
    final allFolders = await ApiService.getFolders(_apiToken);
    List<Map<String, dynamic>> path = [];
    int? id = _currentFolderId;
    while (id != null) {
      final folder = allFolders.firstWhere((f) => f['id'] == id, orElse: () => null);
      if (folder == null) break;
      path.insert(0, {'id': folder['id'], 'name': folder['name']});
      id = folder['parent_id'];
    }
    if (mounted) setState(() => _folderPath = path);
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Новая папка'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Название папки'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Создать'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final folderId = await ApiService.createFolder(_apiToken, name, parentId: _currentFolderId);
      if (folderId != null && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Папка "$name" создана')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка создания папки')));
      }
    }
  }

  Future<void> _renameFolder(dynamic folder) async {
    final controller = TextEditingController(text: folder['name']);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переименовать папку'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Новое имя'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Переименовать'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != folder['name']) {
      final success = await ApiService.renameFolder(_apiToken, folder['id'], newName);
      if (success && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Папка переименована')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка')));
      }
    }
  }

  Future<void> _deleteFolder(dynamic folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить папку "${folder['name']}"?'),
        content: Text('Все файлы внутри будут перемещены в текущую папку. Продолжить?'),
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
      final success = await ApiService.deleteFolder(_apiToken, folder['id'], force: true);
      if (success && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Папка удалена')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления')));
      }
    }
  }

  void _showFolderMenu(dynamic folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(folder['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _renameFolder(folder);
              },
              icon: Icon(Icons.edit),
              label: Text('Переименовать'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _deleteFolder(folder);
              },
              icon: Icon(Icons.delete, color: Colors.red),
              label: Text('Удалить', style: TextStyle(color: Colors.red)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveFile(dynamic file) async {
    final allFolders = await ApiService.getFolders(_apiToken);
    final chosenFolderId = await showDialog<int?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Переместить "${file['original_name']}" в папку'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: Text('📁 Корень'),
          ),
          ...allFolders.map((folder) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, folder['id']),
            child: Text('📁 ${folder['name']}'),
          )),
        ],
      ),
    );
    if (chosenFolderId != null && mounted) {
      final success = await ApiService.moveFile(_apiToken, file['id'], chosenFolderId == 0 ? null : chosenFolderId);
      if (success && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Файл перемещён')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка перемещения')));
      }
    }
  }

  // === ЗАГРУЗКА ФАЙЛА С ПРОГРЕССОМ ===
  Future<void> _uploadFile(File file, String fileName, bool isPublic) async {
    double progress = 0.0;
    
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (progress < 0.95) {
        progress += 0.05;
        if (mounted) {
          setState(() {});
        }
      } else if (progress >= 0.95 && timer.isActive) {
        timer.cancel();
      }
    });
    
    final success = await ApiService.uploadFile(
      _apiToken, 
      file, 
      fileName, 
      isPublic: isPublic,
      folderId: _currentFolderId,
    );
    
    _progressTimer?.cancel();
    _progressTimer = null;
    
    if (success && mounted) {
      progress = 1.0;
      setState(() {});
      await _loadContent();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $fileName загружен!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Ошибка загрузки')),
      );
    }
  }

  // === СКАЧИВАНИЕ ФАЙЛА С ПРОГРЕССОМ ===
  Future<void> _downloadFile(int fileId, String fileName) async {
    double progress = 0.0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.microtask(() async {
              final success = await ApiService.downloadFile(
                _apiToken, 
                fileId, 
                fileName,
              );
              
              if (mounted && dialogContext.mounted) {
                Navigator.pop(dialogContext);
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
            });
            
            return AlertDialog(
              title: Text('Скачивание: $fileName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  SizedBox(height: 16),
                  Text('Загрузка...'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteFile(int fileId, String fileName, int ownerId) async {
    final canDelete = _isAdmin || ownerId == _currentUserId;

    if (!canDelete && mounted) {
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

    if (confirm == true && mounted) {
      final success = await ApiService.deleteFile(_apiToken, fileId);
      if (success && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Файл удалён')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка удаления')),
        );
      }
    }
  }

  Future<void> _renameFile(dynamic file) async {
    final ownerId = file['user_id'];
    final canRename = _isAdmin || ownerId == _currentUserId;

    if (!canRename && mounted) {
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

    if (newName != null && newName.isNotEmpty && newName != file['original_name'] && mounted) {
      final success = await ApiService.renameFile(_apiToken, file['id'], newName);
      if (success && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл переименован в "$newName"')),
        );
      } else if (mounted) {
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
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadContent();
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
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _moveFile(file);
              },
              icon: Icon(Icons.drive_file_move, color: Colors.orange),
              label: Text('Переместить в папку'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Поиск файлов...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _loadContent();
                },
              )
            : (_folderPath.isEmpty
                ? Text('🍖 Кусочница')
                : Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _currentFolderId = _folderPath.length > 1 
                                ? _folderPath[_folderPath.length - 2]['id'] 
                                : null;
                          });
                          _loadContent();
                        },
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _folderPath.map((folder) => 
                              Text(' / ${folder['name']}')
                            ).toList(),
                          ),
                        ),
                      ),
                    ],
                  )),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                  _loadContent();
                } else {
                  _isSearching = true;
                  _searchQuery = '';
                }
              });
            },
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () async {
                final needRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(apiToken: _apiToken),
                  ),
                );
                if (needRefresh == true && mounted) {
                  await _loadContent();
                }
              },
              tooltip: 'Профиль',
            ),
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
            IconButton(icon: Icon(Icons.refresh), onPressed: _loadContent),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : (_folders.isEmpty && _files.isEmpty
              ? Center(child: Text('Нет файлов и папок. Нажми + чтобы добавить'))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: _folders.length + _files.length,
                  itemBuilder: (context, index) {
                    if (index < _folders.length) {
                      return FolderPill(
                        folder: _folders[index],
                        index: index,
                        onTap: () {
                          setState(() => _currentFolderId = _folders[index]['id']);
                          _loadContent();
                        },
                        onLongPress: () => _showFolderMenu(_folders[index]),
                      );
                    } else {
                      final fileIndex = index - _folders.length;
                      return FilePill(
                        file: _files[fileIndex],
                        index: fileIndex,
                        onTap: () => _showFileMenu(_files[fileIndex]),
                      );
                    }
                  },
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: _createFolder,
        child: Icon(Icons.create_new_folder),
        tooltip: 'Создать папку',
      ),
    );
  }
}