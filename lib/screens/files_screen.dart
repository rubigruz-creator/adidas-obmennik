import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../widgets/file_card.dart';
import '../widgets/file_list_tile.dart';
import '../widgets/folder_card.dart';
import '../widgets/folder_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/breadcrumb_chips.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'file_operations.dart';
import 'folder_operations.dart';
import 'upload_operations.dart';

enum ViewMode { grid, list }

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  _FilesScreenState createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen>
    with FileOperations, FolderOperations, UploadOperations {
  List<dynamic> folders = [];
  List<dynamic> files = [];
  bool isLoading = true;
  String apiToken = '';
  int currentUserId = 0;
  bool isAdmin = false;
  int? currentFolderId;
  List<Map<String, dynamic>> folderPath = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isSearching = false;

  ViewMode viewMode = ViewMode.grid;
  String sortBy = 'date';
  bool sortAsc = false;
  Set<String> typeFilters = {};
  Set<String> attributeFilters = {};

  Timer? debounceTimer;

  // ─── Режим выбора (v5.5) ───────────────────────────────────────
  bool isSelectionMode = false;
  final Set<int> selectedItemIds = {};

  /// Вход в режим выбора с уже выбранным элементом
  void enterSelectionMode(int itemId) {
    setState(() {
      isSelectionMode = true;
      selectedItemIds.clear();
      selectedItemIds.add(itemId);
    });
  }

  /// Выход из режима выбора
  void exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedItemIds.clear();
    });
  }

  /// Переключение выбора элемента
  void toggleSelection(int itemId) {
    setState(() {
      if (selectedItemIds.contains(itemId)) {
        selectedItemIds.remove(itemId);
        // Если сняли последний — выходим из режима
        if (selectedItemIds.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedItemIds.add(itemId);
      }
    });
  }

  /// Собрать выбранные файлы (для групповых операций)
  List<dynamic> get _selectedFiles {
    return files.where((f) => selectedItemIds.contains(f['id'])).toList();
  }

  /// Собрать выбранные папки
  List<dynamic> get _selectedFolders {
    return folders.where((f) => selectedItemIds.contains(f['id'])).toList();
  }

  /// Общее количество выбранных элементов
  int get _selectedCount => selectedItemIds.length;

  // ─── Групповое удаление ────────────────────────────────────────
  Future<void> _deleteSelected() async {
    final count = _selectedCount;
    if (count == 0) return;

    // Собираем все выбранные элементы (и файлы, и папки)
    final selectedFiles = _selectedFiles;
    final selectedFolders = _selectedFolders;
    final totalItems = selectedFiles.length + selectedFolders.length;

    // Диалог подтверждения
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить выбранное?'),
        content: Text('Вы уверены, что хотите удалить $totalItems элемент(ов)?\nЭто действие необратимо.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Показываем SnackBar с прогрессом
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Удаление $totalItems элемент(ов)...'), duration: const Duration(seconds: 10)),
    );

    int deleted = 0;
    int errors = 0;

    // Удаляем файлы
    for (final file in selectedFiles) {
      final fileId = file['id'] as int;
      final success = await ApiService.deleteFile(apiToken, fileId);
      if (success) {
        deleted++;
      } else {
        errors++;
      }
    }

    // Удаляем папки
    for (final folder in selectedFolders) {
      final folderId = folder['id'] as int;
      final success = await ApiService.deleteFolder(apiToken, folderId);
      if (success) {
        deleted++;
      } else {
        errors++;
      }
    }

    // Выходим из режима выбора и обновляем список
    exitSelectionMode();
    await loadContent();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors > 0
              ? 'Удалено: $deleted, ошибок: $errors'
              : 'Удалено: $deleted'),
          backgroundColor: errors > 0 ? Colors.orange : null,
        ),
      );
    }
  }

  // ─── Групповое перемещение ─────────────────────────────────────
  Future<void> _moveSelected() async {
    final selectedFiles = _selectedFiles;
    final selectedFolders = _selectedFolders;
    final totalItems = selectedFiles.length + selectedFolders.length;
    if (totalItems == 0) return;

    // Получаем список всех папок для выбора целевой
    final allFolders = await ApiService.getFolders(apiToken);

    // Исключаем из списка выбранные папки (нельзя переместить папку в саму себя)
    final availableFolders = allFolders.where((f) => !selectedItemIds.contains(f['id'])).toList();

    // Диалог выбора целевой папки
    final targetFolderId = await showDialog<int?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Переместить $totalItems элемент(ов) в папку'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null), // null = корень
            child: const Text('📁 Корень'),
          ),
          ...availableFolders.map((folder) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, folder['id'] as int?),
            child: Text('📁 ${folder['name']}'),
          )),
        ],
      ),
    );

    if (targetFolderId == null && targetFolderId != 0) {
      // Пользователь закрыл диалог (null от SimpleDialog при закрытии)
      // targetFolderId будет null, если нажали "Корень" — это ок.
      // Но если просто закрыли — тоже null. Проверим через mounted.
      return;
    }

    if (!mounted) return;

    // Показываем прогресс
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Перемещение $totalItems элемент(ов)...'), duration: const Duration(seconds: 10)),
    );

    int moved = 0;
    int errors = 0;

    // Перемещаем файлы
    for (final file in selectedFiles) {
      final fileId = file['id'] as int;
      final success = await ApiService.moveFile(apiToken, fileId, targetFolderId);
      if (success) {
        moved++;
      } else {
        errors++;
      }
    }

    // Перемещаем папки
    for (final folder in selectedFolders) {
      final folderId = folder['id'] as int;
      final success = await ApiService.moveFolder(apiToken, folderId, targetFolderId);
      if (success) {
        moved++;
      } else {
        errors++;
      }
    }

    // Выходим из режима и обновляем
    exitSelectionMode();
    await loadContent();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors > 0
              ? 'Перемещено: $moved, ошибок: $errors'
              : 'Перемещено: $moved'),
          backgroundColor: errors > 0 ? Colors.orange : null,
        ),
      );
    }
  }

  // ─── Существующие константы и переопределения ──────────────────
  static const String _viewModeKey = 'view_mode';

  @override
  String get token => apiToken;
  @override
  int get userId => currentUserId;
  @override
  bool get admin => isAdmin;
  @override
  int? get folderId => currentFolderId;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_viewModeKey) ?? 'grid';
    setState(() {
      viewMode = mode == 'list' ? ViewMode.list : ViewMode.grid;
    });
  }

  Future<void> _saveViewMode(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode == ViewMode.list ? 'list' : 'grid');
  }

  Future<void> _checkAuthAndLoad() async {
    final t = await AuthService.getToken();
    final uid = await AuthService.getUserId();
    final adm = await AuthService.getIsAdmin();

    if (t == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
      return;
    }

    if (mounted) {
      setState(() {
        apiToken = t;
        currentUserId = uid ?? 0;
        isAdmin = adm == 1;
      });
    }

    await loadContent();
  }

  Future<void> loadContent() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final content = await ApiService.getFolderContent(
        apiToken,
        folderId: currentFolderId,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          folders = _applySorting(content['folders']);
          files = _applyFiltersAndSorting(content['files']);
        });
      }

      if (currentFolderId != null) {
        await _loadFolderPath();
      } else {
        if (mounted) setState(() => folderPath = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadFolderPath() async {
    final allFolders = await ApiService.getFolders(apiToken);
    List<Map<String, dynamic>> path = [];
    int? id = currentFolderId;
    while (id != null) {
      final folder = allFolders.firstWhere((f) => f['id'] == id, orElse: () => null);
      if (folder == null) break;
      path.insert(0, {'id': folder['id'], 'name': folder['name']});
      id = folder['parent_id'];
    }
    if (mounted) setState(() => folderPath = path);
  }

  void _goToParentFolder() {
    if (folderPath.length > 1) {
      final parentFolder = folderPath[folderPath.length - 2];
      setState(() {
        currentFolderId = parentFolder['id'];
      });
    } else {
      setState(() {
        currentFolderId = null;
        folderPath = [];
      });
    }
    loadContent();
  }

  Future<bool> _onWillPop() async {
    if (currentFolderId != null) {
      _goToParentFolder();
      return false;
    }
    return true;
  }

  List<dynamic> _applyFiltersAndSorting(List<dynamic> fileList) {
    List<dynamic> result = fileList;

    if (typeFilters.isNotEmpty) {
      result = result.where((f) {
        final type = (f['file_type'] ?? '').toLowerCase();
        for (final filter in typeFilters) {
          switch (filter) {
            case 'image':
              if (type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('webp') || type.contains('gif')) return true;
              break;
            case 'pdf':
              if (type.contains('pdf')) return true;
              break;
            case 'doc':
              if (type.contains('doc') || type.contains('docx') || type.contains('rtf')) return true;
              break;
            case 'xls':
              if (type.contains('xls') || type.contains('xlsx') || type.contains('csv')) return true;
              break;
            case 'archive':
              if (type.contains('zip') || type.contains('rar') || type.contains('7z') || type.contains('tar')) return true;
              break;
            case 'audio':
              if (type.contains('mp3') || type.contains('wav') || type.contains('flac')) return true;
              break;
            case 'video':
              if (type.contains('mp4') || type.contains('avi') || type.contains('mkv')) return true;
              break;
            case 'text':
              if (type.contains('txt') || type.contains('log') || type.contains('md')) return true;
              break;
            case 'code':
              if (type.contains('php') || type.contains('js') || type.contains('dart') || type.contains('py')) return true;
              break;
            case 'apk':
              if (type.contains('apk')) return true;
              break;
          }
        }
        return false;
      }).toList();
    }

    if (attributeFilters.contains('mine')) {
      result = result.where((f) => f['user_id'] == currentUserId).toList();
    }
    if (attributeFilters.contains('others')) {
      result = result.where((f) => f['user_id'] != currentUserId).toList();
    }
    if (attributeFilters.contains('new')) {
      result = result.where((f) => f['is_new'] == true).toList();
    }
    if (attributeFilters.contains('viewed')) {
      result = result.where((f) => f['is_new'] == false).toList();
    }

    return _applySorting(result);
  }

  List<dynamic> _applySorting(List<dynamic> items) {
    List<dynamic> sorted = List.from(items);
    switch (sortBy) {
      case 'name':
        sorted.sort((a, b) => sortAsc
            ? (a['original_name'] ?? a['name']).compareTo(b['original_name'] ?? b['name'])
            : (b['original_name'] ?? b['name']).compareTo(a['original_name'] ?? a['name']));
        break;
      case 'size':
        sorted.sort((a, b) => sortAsc
            ? (a['file_size'] ?? 0).compareTo(b['file_size'] ?? 0)
            : (b['file_size'] ?? 0).compareTo(a['file_size'] ?? 0));
        break;
      case 'owner':
        sorted.sort((a, b) {
          final aOwner = (a['owner_nickname'] ?? 'яяя').toString().toLowerCase();
          final bOwner = (b['owner_nickname'] ?? 'яяя').toString().toLowerCase();
          return sortAsc ? aOwner.compareTo(bOwner) : bOwner.compareTo(aOwner);
        });
        break;
      case 'visibility':
        sorted.sort((a, b) {
          final aPublic = a['is_public'] == 1 ? 1 : 0;
          final bPublic = b['is_public'] == 1 ? 1 : 0;
          return sortAsc ? aPublic.compareTo(bPublic) : bPublic.compareTo(aPublic);
        });
        break;
      case 'date':
      default:
        sorted.sort((a, b) => sortAsc
            ? (a['upload_date'] ?? a['created_at'] ?? '').compareTo(b['upload_date'] ?? b['created_at'] ?? '')
            : (b['upload_date'] ?? b['created_at'] ?? '').compareTo(a['upload_date'] ?? a['created_at'] ?? ''));
        break;
    }
    return sorted;
  }

  Future<void> logout() async {
    WebSocketService().disconnect();
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  void toggleViewMode() {
    setState(() {
      viewMode = viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    });
    _saveViewMode(viewMode);
  }

  void showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('По дате'), leading: const Icon(Icons.date_range), onTap: () { setState(() { sortBy = 'date'; sortAsc = false; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: const Text('По имени'), leading: const Icon(Icons.sort_by_alpha), onTap: () { setState(() { sortBy = 'name'; sortAsc = true; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: const Text('По размеру'), leading: const Icon(Icons.data_usage), onTap: () { setState(() { sortBy = 'size'; sortAsc = false; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: const Text('По хозяину'), leading: const Icon(Icons.person), onTap: () { setState(() { sortBy = 'owner'; sortAsc = true; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: const Text('По типу (Общий/Личный)'), leading: const Icon(Icons.visibility), onTap: () { setState(() { sortBy = 'visibility'; sortAsc = false; }); loadContent(); Navigator.pop(context); }),
        ],
      ),
    );
  }

  void showFABMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.create_new_folder), title: const Text('Создать папку'), onTap: () { Navigator.pop(context); createFolder(); }),
            ListTile(leading: const Icon(Icons.attach_file), title: const Text('Загрузить файлы'), onTap: () { Navigator.pop(context); pickMultipleFiles(); }),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Фото из галереи'), onTap: () { Navigator.pop(context); pickImageFromGallery(); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Фото с камеры'), onTap: () { Navigator.pop(context); takePhoto(); }),
          ],
        ),
      ),
    );
  }

  bool isImageType(String? type) {
    if (type == null) return false;
    final t = type.toLowerCase();
    return t.contains('jpg') || t.contains('jpeg') || t.contains('png') || t.contains('webp') || t.contains('gif') || t.contains('bmp');
  }

  // ─── Сборка AppBar ─────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);

    if (isSelectionMode) {
      // AppBar режима выбора
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: exitSelectionMode,
          tooltip: 'Отменить выбор',
        ),
        title: Text('Выбрано: $_selectedCount'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _selectedCount > 0 ? _deleteSelected : null,
            tooltip: 'Удалить выбранное',
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move),
            onPressed: _selectedCount > 0 ? _moveSelected : null,
            tooltip: 'Переместить выбранное',
          ),
        ],
      );
    }

    // Обычный AppBar
    return AppBar(
      leading: currentFolderId != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goToParentFolder,
              tooltip: 'Назад',
            )
          : (isSearching
              ? null
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/logo/adidas_logo.svg',
                    width: 32,
                    height: 32,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                )),
      title: isSearching
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
                debounceTimer?.cancel();
                debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  setState(() => _searchQuery = value);
                  loadContent();
                });
              },
            )
          : (folderPath.isEmpty ? null : Text(folderPath.last['name'])),
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              if (isSearching) {
                isSearching = false;
                _searchController.clear();
                _searchQuery = '';
                typeFilters.clear();
                attributeFilters.clear();
                loadContent();
              } else {
                isSearching = true;
                _searchQuery = '';
              }
            });
          },
        ),
        if (!isSearching) ...[
          IconButton(
            icon: Icon(viewMode == ViewMode.grid ? Icons.list : Icons.grid_view),
            onPressed: toggleViewMode,
            tooltip: viewMode == ViewMode.grid ? 'Список' : 'Сетка',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: showSortMenu,
            tooltip: 'Сортировка',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              final needRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(apiToken: apiToken)),
              );
              if (needRefresh == true && mounted) await loadContent();
            },
            tooltip: 'Профиль',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Выйти',
          ),
        ],
      ],
    );
  }

  // ─── Основной build ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentFolderId == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && currentFolderId != null) {
          _goToParentFolder();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Column(
              children: [
                if (folderPath.isNotEmpty)
                  BreadcrumbChips(path: folderPath, onSelected: (folderId, index) { setState(() => currentFolderId = folderId); loadContent(); }),
                if (isSearching) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Wrap(
                      spacing: 6,
                      children: ['Все', 'image', 'pdf', 'doc', 'xls', 'archive', 'audio', 'video', 'text', 'code', 'apk'].map((type) {
                        final selected = type == 'Все' ? typeFilters.isEmpty : typeFilters.contains(type);
                        return FilterChip(
                          label: Text(type == 'Все' ? 'Все' : type),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (type == 'Все') { typeFilters.clear(); } else { if (val) { typeFilters.add(type); } else { typeFilters.remove(type); } }
                            });
                            loadContent();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        FilterChip(
                          label: const Text('Свои'),
                          selected: attributeFilters.contains('mine'),
                          onSelected: (val) {
                            setState(() {
                              if (val) { attributeFilters.add('mine'); attributeFilters.remove('others'); }
                              else { attributeFilters.remove('mine'); }
                            });
                            loadContent();
                          },
                        ),
                        FilterChip(
                          label: const Text('Чужие'),
                          selected: attributeFilters.contains('others'),
                          onSelected: (val) {
                            setState(() {
                              if (val) { attributeFilters.add('others'); attributeFilters.remove('mine'); }
                              else { attributeFilters.remove('others'); }
                            });
                            loadContent();
                          },
                        ),
                        FilterChip(
                          label: const Text('Новые'),
                          selected: attributeFilters.contains('new'),
                          onSelected: (val) {
                            setState(() {
                              if (val) { attributeFilters.add('new'); attributeFilters.remove('viewed'); }
                              else { attributeFilters.remove('new'); }
                            });
                            loadContent();
                          },
                        ),
                        FilterChip(
                          label: const Text('Просмотренные'),
                          selected: attributeFilters.contains('viewed'),
                          onSelected: (val) {
                            setState(() {
                              if (val) { attributeFilters.add('viewed'); attributeFilters.remove('new'); }
                              else { attributeFilters.remove('viewed'); }
                            });
                            loadContent();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : folders.isEmpty && files.isEmpty
                          ? const EmptyState()
                          : RefreshIndicator(
                              onRefresh: loadContent,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: viewMode == ViewMode.grid ? buildGridView() : buildListView(),
                              ),
                            ),
                ),
              ],
            ),
            if (!isSelectionMode)
              Positioned(
                left: 16,
                bottom: 46,
                child: FloatingActionButton(
                  heroTag: 'camera',
                  onPressed: takePhoto,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.camera_alt),
                ),
              ),
          ],
        ),
        floatingActionButton: isSelectionMode
            ? null
            : FloatingActionButton(
                heroTag: 'main',
                onPressed: showFABMenu,
                tooltip: 'Добавить',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  // ─── GridView с поддержкой выбора ──────────────────────────────
  Widget buildGridView() {
    return GridView.builder(
      key: PageStorageKey('grid_${currentFolderId ?? 'root'}'),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: folders.length + files.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          final folder = folders[index];
          final folderId = folder['id'] as int;
          return FolderCard(
            folder: folder,
            isSelectionMode: isSelectionMode,
            isSelected: selectedItemIds.contains(folderId),
            onTap: () {
              if (isSelectionMode) {
                toggleSelection(folderId);
              } else {
                setState(() => currentFolderId = folderId);
                loadContent();
              }
            },
            onLongPress: () {
              if (!isSelectionMode) {
                enterSelectionMode(folderId);
              }
            },
          );
        } else {
          final file = files[index - folders.length];
          final fileId = file['id'] as int;
          return FileCard(
            file: file,
            apiToken: apiToken,
            isSelectionMode: isSelectionMode,
            isSelected: selectedItemIds.contains(fileId),
            onTap: () {
              if (isSelectionMode) {
                toggleSelection(fileId);
              } else {
                showFileMenu(file);
              }
            },
            onLongPress: () {
              if (!isSelectionMode) {
                enterSelectionMode(fileId);
              }
            },
          );
        }
      },
    );
  }

  // ─── ListView с поддержкой выбора ──────────────────────────────
  Widget buildListView() {
    return ListView.builder(
      key: PageStorageKey('list_${currentFolderId ?? 'root'}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: folders.length + files.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          final folder = folders[index];
          final folderId = folder['id'] as int;
          return FolderListTile(
            folder: folder,
            isSelectionMode: isSelectionMode,
            isSelected: selectedItemIds.contains(folderId),
            onTap: () {
              if (isSelectionMode) {
                toggleSelection(folderId);
              } else {
                setState(() => currentFolderId = folderId);
                loadContent();
              }
            },
            onLongPress: () {
              if (!isSelectionMode) {
                enterSelectionMode(folderId);
              }
            },
          );
        } else {
          final file = files[index - folders.length];
          final fileId = file['id'] as int;
          return FileListTile(
            file: file,
            isSelectionMode: isSelectionMode,
            isSelected: selectedItemIds.contains(fileId),
            onTap: () {
              if (isSelectionMode) {
                toggleSelection(fileId);
              } else {
                showFileMenu(file);
              }
            },
            onLongPress: () {
              if (!isSelectionMode) {
                enterSelectionMode(fileId);
              }
            },
          );
        }
      },
    );
  }
}