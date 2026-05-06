import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/file_card.dart';
import '../widgets/file_list_tile.dart';
import '../widgets/folder_card.dart';
import '../widgets/folder_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/breadcrumb_chips.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/websocket_service.dart';
import 'package:open_file/open_file.dart';
import 'dart:io' show File, Directory;  // уже есть, но убедитесь
import 'package:path_provider/path_provider.dart';  // добавьте эту строку
enum ViewMode { grid, list }

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

  ViewMode _viewMode = ViewMode.grid;
  String _sortBy = 'date'; // 'date', 'name', 'size'
  bool _sortAsc = false;
  Set<String> _typeFilters = {}; // выбранные типы

  Timer? _progressTimer;
  Timer? _debounceTimer;

  // Сохранение состояния просмотра
  static const String _viewModeKey = 'view_mode';

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_viewModeKey) ?? 'grid';
    setState(() {
      _viewMode = mode == 'list' ? ViewMode.list : ViewMode.grid;
    });
  }

  Future<void> _saveViewMode(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode == ViewMode.list ? 'list' : 'grid');
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
          _folders = _applySorting(content['folders']);
          _files = _applyFiltersAndSorting(content['files']);
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

  // Фильтрация по типу и сортировка
  List<dynamic> _applyFiltersAndSorting(List<dynamic> files) {
    List<dynamic> result = files;
    if (_typeFilters.isNotEmpty) {
      result = result.where((f) {
        final type = (f['file_type'] ?? '').toLowerCase();
        for (final filter in _typeFilters) {
          switch (filter) {
            case 'image': if (type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('webp') || type.contains('gif')) return true; break;
            case 'pdf': if (type.contains('pdf')) return true; break;
            case 'doc': if (type.contains('doc') || type.contains('docx')) return true; break;
            case 'xls': if (type.contains('xls') || type.contains('xlsx') || type.contains('csv')) return true; break;
            case 'archive': if (type.contains('zip') || type.contains('rar') || type.contains('7z') || type.contains('tar')) return true; break;
            case 'audio': if (type.contains('mp3') || type.contains('wav') || type.contains('flac')) return true; break;
            case 'video': if (type.contains('mp4') || type.contains('avi') || type.contains('mkv')) return true; break;
            case 'text': if (type.contains('txt') || type.contains('log') || type.contains('md')) return true; break;
            case 'code': if (type.contains('php') || type.contains('js') || type.contains('dart') || type.contains('py')) return true; break;
          }
        }
        return false;
      }).toList();
    }
    return _applySorting(result);
  }

  List<dynamic> _applySorting(List<dynamic> items) {
    List<dynamic> sorted = List.from(items);
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => _sortAsc 
            ? (a['original_name'] ?? a['name']).compareTo(b['original_name'] ?? b['name'])
            : (b['original_name'] ?? b['name']).compareTo(a['original_name'] ?? a['name']));
        break;
      case 'size':
        sorted.sort((a, b) => _sortAsc
            ? (a['file_size'] ?? 0).compareTo(b['file_size'] ?? 0)
            : (b['file_size'] ?? 0).compareTo(a['file_size'] ?? 0));
        break;
      case 'date':
      default:
        sorted.sort((a, b) => _sortAsc
            ? (a['upload_date'] ?? a['created_at'] ?? '').compareTo(b['upload_date'] ?? b['created_at'] ?? '')
            : (b['upload_date'] ?? b['created_at'] ?? '').compareTo(a['upload_date'] ?? a['created_at'] ?? ''));
        break;
    }
    return sorted;
  }

  // === Все существующие методы (без изменений) ===
  // _createFolder, _renameFolder, _deleteFolder, _showFolderMenu,
  // _moveFile, _uploadFile, _downloadFile, _deleteFile, _renameFile, _showFileMenu,
  // _logout, _showVisibilityDialog, _pickAnyFile, _pickImageFromGallery, _takePhoto

  // (копируем их дословно из исходного файла, они не меняются, поэтому здесь опущены для краткости)

  // ОСТАВИТЬ ВСЕ МЕТОДЫ КАК В ИСХОДНОМ КОДЕ (приведены ниже)

  // ... все методы из оригинального files_screen.dart (без изменений)

  // ==================================================



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

  Future<void> _uploadFile(File file, String fileName, bool isPublic) async {
    double progress = 0.0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (progress < 0.95) {
        progress += 0.05;
        if (mounted) setState(() {});
      } else if (progress >= 0.95 && timer.isActive) {
        timer.cancel();
      }
    });
    final success = await ApiService.uploadFile(
      _apiToken, file, fileName, isPublic: isPublic, folderId: _currentFolderId,
    );
    _progressTimer?.cancel();
    _progressTimer = null;
    if (success && mounted) {
      progress = 1.0;
      setState(() {});
      await _loadContent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $fileName загружен!')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка загрузки')));
    }
  }

  Future<void> _downloadFile(int fileId, String fileName, String fileType) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isCompleted = false;
        bool hasError = false;
        String? savedPath;
        double progress = 0.0;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.microtask(() async {
              try {
                // Пробуем скачать через простой метод (он надёжнее для поиска файла)
                final success = await ApiService.downloadFile(
                  _apiToken,
                  fileId,
                  fileName,
                );
                
                if (!dialogContext.mounted || !mounted) return;
                
                if (success) {
                  // Ищем сохранённый файл
                  final dir = Directory('/storage/emulated/0/Download');
                  File? foundFile;
                  
                  if (await dir.exists()) {
                    // Ищем точное совпадение
                    final exactFile = File('${dir.path}/$fileName');
                    if (await exactFile.exists()) {
                      foundFile = exactFile;
                    } else {
                      // Ищем по началу имени (мог добавиться суффикс _1, _2 и т.д.)
                      final files = dir.listSync()
                          .whereType<File>()
                          .where((f) {
                            final name = f.uri.pathSegments.last;
                            return name == fileName || name.startsWith(fileName.replaceAll(RegExp(r'\.[^.]+$'), '')) && name.endsWith(fileName.split('.').last);
                          })
                          .toList()
                        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
                      
                      if (files.isNotEmpty) {
                        foundFile = files.first;
                      }
                    }
                  }
                  
                  if (foundFile != null) {
                    savedPath = foundFile.path;
                    setDialogState(() {
                      isCompleted = true;
                      progress = 1.0;
                    });
                  } else {
                    // Ищем в папке приложения
                    try {
                      final appDir = await getApplicationDocumentsDirectory();
                      if (await File('${appDir.path}/$fileName').exists()) {
                        savedPath = '${appDir.path}/$fileName';
                        setDialogState(() {
                          isCompleted = true;
                          progress = 1.0;
                        });
                      } else {
                        setDialogState(() => hasError = true);
                      }
                    } catch (e) {
                      setDialogState(() => hasError = true);
                    }
                  }
                } else {
                  setDialogState(() => hasError = true);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  setDialogState(() => hasError = true);
                }
              }
            });
            
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasError ? '❌ Ошибка' : (isCompleted ? '✅ Скачано' : 'Скачивание'),
                    ),
                  ),
                  if (isCompleted || hasError)
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                ],
              ),
              content: SingleChildScrollView(  // ← Вот исправление переполнения
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasError) ...[
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 12),
                      Text(
                        'Не удалось скачать файл',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        fileName,
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            // Повторная попытка
                            _downloadFile(fileId, fileName, fileType);
                          },
                          child: Text('Повторить'),
                        ),
                      ),
                    ] else if (!isCompleted) ...[
                      LinearProgressIndicator(value: progress > 0 ? progress : null),
                      SizedBox(height: 16),
                      Text('Загрузка...'),
                      Text(
                        fileName,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ] else ...[
                      Icon(
                        _getIconForType(fileType),
                        size: 48,
                        color: Theme.of(this.context).colorScheme.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        fileName,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          if (savedPath != null) {
                            try {
                              // Используем OpenFile из библиотеки open_file
                              // ignore: depend_on_referenced_packages
                              final result = await OpenFile.open(savedPath!);
                              if (result.type != ResultType.done) {
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(content: Text('Не удалось открыть файл: ${result.message}')),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text('Не удалось открыть файл: $e')),
                                );
                              }
                            }
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder_open, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Сохранён в Downloads',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Нажмите, чтобы открыть',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('image') || type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('webp') || type.contains('gif')) {
      return Icons.image;
    } else if (type.contains('video') || type.contains('mp4') || type.contains('avi') || type.contains('mkv')) {
      return Icons.videocam;
    } else if (type.contains('audio') || type.contains('mp3') || type.contains('wav') || type.contains('flac')) {
      return Icons.audiotrack;
    } else if (type.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (type.contains('text') || type.contains('txt') || type.contains('log')) {
      return Icons.text_snippet;
    } else if (type.contains('zip') || type.contains('rar') || type.contains('archive')) {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }



  Future<void> _deleteFile(int fileId, String fileName, int ownerId) async {
    final canDelete = _isAdmin || ownerId == _currentUserId;
    if (!canDelete && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Нет прав на удаление')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить файл?'),
        content: Text('Вы уверены, что хотите удалить "$fileName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await ApiService.deleteFile(_apiToken, fileId);
      if (success && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Файл удалён')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка удаления')));
      }
    }
  }

  Future<void> _renameFile(dynamic file) async {
    final ownerId = file['user_id'];
    final canRename = _isAdmin || ownerId == _currentUserId;
    if (!canRename && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Нет прав на переименование')));
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
          decoration: InputDecoration(labelText: 'Новое имя', hintText: 'Введите новое имя файла'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Переименовать')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != file['original_name'] && mounted) {
      final success = await ApiService.renameFile(_apiToken, file['id'], newName);
      if (success && mounted) {
        _loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Файл переименован в "$newName"')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка переименования')));
      }
    }
  }


  void _showFileMenu(dynamic file) {
    final ownerId = file['user_id'];
    final canDelete = _isAdmin || ownerId == _currentUserId;
    final isPublic = file['is_public'] == 1;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 90),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(file['original_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Размер: ${file['file_size'] != null ? '${(file['file_size'] / 1048576).toStringAsFixed(1)} MB' : 'неизвестно'}'),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadFile(file['id'], file['original_name'], file['file_type'] ?? '');
                  },
                  icon: Icon(Icons.download),
                  label: Text('Скачать', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _renameFile(file);
                  },
                  icon: Icon(Icons.edit, color: Colors.blue),
                  label: Text('Переименовать', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.blue.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _moveFile(file);
                  },
                  icon: Icon(Icons.drive_file_move, color: Colors.orange),
                  label: Text('Переместить в папку', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.orange.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              if (canDelete) ...[
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteFile(file['id'], file['original_name'], ownerId);
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Удалить', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.red.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    WebSocketService().disconnect();
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Личный')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Общий')),
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

  // === КОНЕЦ НЕИЗМЕННЫХ МЕТОДОВ ===

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    });
    _saveViewMode(_viewMode);
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('По дате'), leading: Icon(Icons.date_range), onTap: () { setState(() { _sortBy = 'date'; _sortAsc = false; }); _loadContent(); Navigator.pop(context); }),
          ListTile(title: Text('По имени'), leading: Icon(Icons.sort_by_alpha), onTap: () { setState(() { _sortBy = 'name'; _sortAsc = true; }); _loadContent(); Navigator.pop(context); }),
          ListTile(title: Text('По размеру'), leading: Icon(Icons.data_usage), onTap: () { setState(() { _sortBy = 'size'; _sortAsc = false; }); _loadContent(); Navigator.pop(context); }),
        ],
      ),
    );
  }

  void _showFABMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.create_new_folder),
              title: Text('Создать папку'),
              onTap: () { Navigator.pop(context); _createFolder(); },
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Загрузить файл'),
              onTap: () { Navigator.pop(context); _pickAnyFile(); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Фото из галереи'),
              onTap: () { Navigator.pop(context); _pickImageFromGallery(); },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Фото с камеры'),
              onTap: () { Navigator.pop(context); _takePhoto(); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onPrimary),
                decoration: InputDecoration(
                  hintText: 'Поиск файлов...',
                  hintStyle: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(Duration(milliseconds: 300), () {
                    setState(() => _searchQuery = value);
                    _loadContent();
                  });
                },
              )
            : (_folderPath.isEmpty
                ? Text('🍖 Кусочница')
                : Text(_folderPath.last['name'])),
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
              icon: Icon(_viewMode == ViewMode.grid ? Icons.list : Icons.grid_view),
              onPressed: _toggleViewMode,
              tooltip: _viewMode == ViewMode.grid ? 'Список' : 'Сетка',
            ),
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: _showSortMenu,
              tooltip: 'Сортировка',
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () async {
                final needRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(apiToken: _apiToken)),
                );
                if (needRefresh == true && mounted) await _loadContent();
              },
              tooltip: 'Профиль',
            ),
            IconButton(icon: Icon(Icons.logout), onPressed: _logout),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_folderPath.isNotEmpty)
            BreadcrumbChips(
              path: _folderPath,
              onSelected: (folderId, index) {
                setState(() => _currentFolderId = folderId);
                _loadContent();
              },
            ),
          if (_isSearching)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 6,
                children: ['Все', 'image', 'pdf', 'doc', 'xls', 'archive', 'audio', 'video', 'text', 'code'].map((type) {
                  final selected = type == 'Все' ? _typeFilters.isEmpty : _typeFilters.contains(type);
                  return FilterChip(
                    label: Text(type == 'Все' ? 'Все' : type),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (type == 'Все') {
                          _typeFilters.clear();
                        } else {
                          if (val) _typeFilters.add(type);
                          else _typeFilters.remove(type);
                        }
                      });
                      _loadContent();
                    },
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _folders.isEmpty && _files.isEmpty
                    ? EmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadContent,
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: _viewMode == ViewMode.grid
                              ? _buildGridView()
                              : _buildListView(),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFABMenu,
        child: Icon(Icons.add),
        tooltip: 'Добавить',
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      key: PageStorageKey('grid_${_currentFolderId ?? 'root'}'),
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _folders.length + _files.length,
      itemBuilder: (context, index) {
        if (index < _folders.length) {
          return FolderCard(
            folder: _folders[index],
            onTap: () {
              setState(() => _currentFolderId = _folders[index]['id']);
              _loadContent();
            },
            onLongPress: () => _showFolderMenu(_folders[index]),
          );
        } else {
          final file = _files[index - _folders.length];
          return FileCard(
            file: file,
            onTap: () => _showFileMenu(file),
            onLongPress: () => _showFileMenu(file),
            apiToken: _apiToken,   // <-- добавить
          );
        }
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      key: PageStorageKey('list_${_currentFolderId ?? 'root'}'),
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _folders.length + _files.length,
      itemBuilder: (context, index) {
        if (index < _folders.length) {
          return FolderListTile(
            folder: _folders[index],
            onTap: () {
              setState(() => _currentFolderId = _folders[index]['id']);
              _loadContent();
            },
            onLongPress: () => _showFolderMenu(_folders[index]),
          );
        } else {
          final file = _files[index - _folders.length];
          return FileListTile(
            file: file,
            onTap: () => _showFileMenu(file),
            onLongPress: () => _showFileMenu(file),
          );
        }
      },
    );
  }
}