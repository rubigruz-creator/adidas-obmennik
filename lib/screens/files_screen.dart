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
import '../utils/app_config.dart';

enum ViewMode { grid, list }

class FilesScreen extends StatefulWidget {
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
    // uploadProgressTimer?.cancel();
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

    // 1. Фильтр по типу (старый)
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

    // 2. Атрибутные фильтры (владелец, новизна)
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
          ListTile(title: Text('По дате'), leading: Icon(Icons.date_range), onTap: () { setState(() { sortBy = 'date'; sortAsc = false; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: Text('По имени'), leading: Icon(Icons.sort_by_alpha), onTap: () { setState(() { sortBy = 'name'; sortAsc = true; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: Text('По размеру'), leading: Icon(Icons.data_usage), onTap: () { setState(() { sortBy = 'size'; sortAsc = false; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: Text('По хозяину'), leading: Icon(Icons.person), onTap: () { setState(() { sortBy = 'owner'; sortAsc = true; }); loadContent(); Navigator.pop(context); }),
          ListTile(title: Text('По типу (Общий/Личный)'), leading: Icon(Icons.visibility), onTap: () { setState(() { sortBy = 'visibility'; sortAsc = false; }); loadContent(); Navigator.pop(context); }),
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
            ListTile(leading: Icon(Icons.create_new_folder), title: Text('Создать папку'), onTap: () { Navigator.pop(context); createFolder(); }),
            ListTile(leading: Icon(Icons.attach_file), title: Text('Загрузить файл'), onTap: () { Navigator.pop(context); pickAnyFile(); }),
            ListTile(leading: Icon(Icons.photo_library), title: Text('Фото из галереи'), onTap: () { Navigator.pop(context); pickImageFromGallery(); }),
            ListTile(leading: Icon(Icons.camera_alt), title: Text('Фото с камеры'), onTap: () { Navigator.pop(context); takePhoto(); }),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: currentFolderId == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && currentFolderId != null) {
          _goToParentFolder();
        }
      },
      child: Scaffold(

appBar: AppBar(
  leading: currentFolderId != null
      ? IconButton(
          icon: Icon(Icons.arrow_back),
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
            debounceTimer = Timer(Duration(milliseconds: 300), () {
              setState(() => _searchQuery = value);
              loadContent();
            });
          },
        )
      : (folderPath.isEmpty
          ? null
          : Text(folderPath.last['name'])),
  actions: [    



          // Кнопка поиска/закрытия поиска
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
          // Остальные кнопки видны только когда поиск НЕ активен
          if (!isSearching) ...[
            IconButton(
              icon: Icon(viewMode == ViewMode.grid ? Icons.list : Icons.grid_view),
              onPressed: toggleViewMode,
              tooltip: viewMode == ViewMode.grid ? 'Список' : 'Сетка',
            ),
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: showSortMenu,
              tooltip: 'Сортировка',
            ),
            IconButton(
              icon: Icon(Icons.person),
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
              icon: Icon(Icons.logout),
              onPressed: logout,
              tooltip: 'Выйти',
            ),
          ],
        ],
      ),


        body: Stack(
          children: [
            Column(
              children: [
                if (folderPath.isNotEmpty)
                  BreadcrumbChips(path: folderPath, onSelected: (folderId, index) { setState(() => currentFolderId = folderId); loadContent(); }),
                if (isSearching) ...[
                  // Первая строка: фильтры по типу
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Wrap(
                      spacing: 6,
                      children: ['Все', 'image', 'pdf', 'doc', 'xls', 'archive', 'audio', 'video', 'text', 'code', 'apk'].map((type) {
                        final selected = type == 'Все' ? typeFilters.isEmpty : typeFilters.contains(type);
                        return FilterChip(
                          label: Text(type == 'Все' ? 'Все' : type),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (type == 'Все') { typeFilters.clear(); } else { if (val) typeFilters.add(type); else typeFilters.remove(type); }
                            });
                            loadContent();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  // Вторая строка: атрибутные фильтры
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        FilterChip(
                          label: Text('Свои'),
                          selected: attributeFilters.contains('mine'),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                attributeFilters.add('mine');
                                attributeFilters.remove('others');
                              } else {
                                attributeFilters.remove('mine');
                              }
                            });
                            loadContent();
                          },
                        ),
                        FilterChip(
                          label: Text('Чужие'),
                          selected: attributeFilters.contains('others'),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                attributeFilters.add('others');
                                attributeFilters.remove('mine');
                              } else {
                                attributeFilters.remove('others');
                              }
                            });
                            loadContent();
                          },
                        ),
                        FilterChip(
                          label: Text('Новые'),
                          selected: attributeFilters.contains('new'),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                attributeFilters.add('new');
                                attributeFilters.remove('viewed');
                              } else {
                                attributeFilters.remove('new');
                              }
                            });
                            loadContent();
                          },
                        ),
                        FilterChip(
                          label: Text('Просмотренные'),
                          selected: attributeFilters.contains('viewed'),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                attributeFilters.add('viewed');
                                attributeFilters.remove('new');
                              } else {
                                attributeFilters.remove('viewed');
                              }
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
                      ? Center(child: CircularProgressIndicator())
                      : folders.isEmpty && files.isEmpty
                          ? EmptyState()
                          : RefreshIndicator(
                              onRefresh: loadContent,
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: viewMode == ViewMode.grid ? buildGridView() : buildListView(),
                              ),
                            ),
                ),
              ],
            ),
            // Кнопка камеры в левом нижнем углу
            Positioned(
              left: 16,
              bottom: 46,
              child: FloatingActionButton(
                heroTag: 'camera',
                onPressed: takePhoto,
                backgroundColor: Colors.red,
                child: Icon(Icons.camera_alt),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'main',
          onPressed: showFABMenu,
          child: Icon(Icons.add),
          tooltip: 'Добавить',
        ),
      ),
    );
  }

  Widget buildGridView() {
    return GridView.builder(
      key: PageStorageKey('grid_${currentFolderId ?? 'root'}'),
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: folders.length + files.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          return FolderCard(folder: folders[index], onTap: () { setState(() => currentFolderId = folders[index]['id']); loadContent(); }, onLongPress: () => showFolderMenu(folders[index]));
        } else {
          final file = files[index - folders.length];
          return FileCard(file: file, onTap: () => showFileMenu(file), onLongPress: () => showFileMenu(file), apiToken: apiToken);
        }
      },
    );
  }

  Widget buildListView() {
    return ListView.builder(
      key: PageStorageKey('list_${currentFolderId ?? 'root'}'),
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: folders.length + files.length,
      itemBuilder: (context, index) {
        if (index < folders.length) {
          return FolderListTile(folder: folders[index], onTap: () { setState(() => currentFolderId = folders[index]['id']); loadContent(); }, onLongPress: () => showFolderMenu(folders[index]));
        } else {
          final file = files[index - folders.length];
          return FileListTile(file: file, onTap: () => showFileMenu(file), onLongPress: () => showFileMenu(file));
        }
      },
    );
  }
}