import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/format_date.dart';
import '../utils/format_file_size.dart';

class AuditLogScreen extends StatefulWidget {
  final String apiToken;
  final Map<String, dynamic> user;

  const AuditLogScreen({
    Key? key,
    required this.apiToken,
    required this.user,
  }) : super(key: key);

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 50;

  // Фильтры
  int? _filterUserId;
  String? _filterAction;
  String? _filterDateFrom;
  String? _filterDateTo;

  // Иконки для действий
  static const Map<String, IconData> _actionIcons = {
    'login': Icons.login,
    'logout': Icons.logout,
    'upload': Icons.upload_file,
    'download': Icons.download,
    'delete': Icons.delete,
    'delete_folder': Icons.folder_delete,
    'rename': Icons.drive_file_rename_outline,
    'rename_folder': Icons.drive_file_rename_outline,
    'move': Icons.move_up,
    'move_folder': Icons.move_up,
    'create_folder': Icons.create_new_folder,
    'toggle_visibility': Icons.visibility,
    'share': Icons.share,
  };

  static const List<String> _actions = [
    'login', 'upload', 'download', 'delete',
    'delete_folder', 'rename', 'rename_folder', 'move',
    'move_folder', 'create_folder', 'toggle_visibility', 'share'
  ];

  // Названия действий
  static const Map<String, String> _actionLabels = {
    'login': 'Вход',
    'logout': 'Выход',
    'upload': 'Загрузка',
    'download': 'Скачивание',
    'delete': 'Удаление файла',
    'delete_folder': 'Удаление папки',
    'rename': 'Переименование',
    'rename_folder': 'Переименование папки',
    'move': 'Перемещение файла',
    'move_folder': 'Перемещение папки',
    'create_folder': 'Создание папки',
    'toggle_visibility': 'Видимость',
    'share': 'Ссылка',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _logs.clear();
    });

    await _loadLogs(reset: true);
  }

  Future<void> _loadLogs({bool reset = false}) async {
    if (_isLoading && !reset) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getAuditLog(
        widget.apiToken,
        limit: _limit,
        offset: _offset,
        userId: _filterUserId,
        action: _filterAction,
        dateFrom: _filterDateFrom,
        dateTo: _filterDateTo,
      );

      if (response['success'] == true) {
        final data = response['data'] as List;
        final total = response['total'] as int;

        setState(() {
          if (reset) _logs.clear();
          _logs.addAll(data.cast<Map<String, dynamic>>());
          _hasMore = _logs.length < total;
          _offset = _logs.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    await _loadLogs();
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  String _formatDetails(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? '';
    final details = log['details'];

    if (details == null) return '';

    if (details is Map<String, dynamic>) {
      switch (action) {
        case 'upload':
          final fileName = details['file_name'] ?? '';
          final fileSize = details['file_size'] ?? 0;
          return '📎 $fileName (${formatFileSize(fileSize is int ? fileSize : 0)})';
        case 'download':
          return '⬇ ${details['file_name'] ?? ''}';
        case 'delete':
          return '🗑 ${details['file_name'] ?? ''}';
        case 'delete_folder':
          return '🗑 ${details['folder_name'] ?? ''}';
        case 'rename':
          return '✏ ${details['old_name'] ?? ''} → ${details['new_name'] ?? ''}';
        case 'rename_folder':
          return '✏ ${details['old_name'] ?? ''} → ${details['new_name'] ?? ''}';
        case 'move':
          return '📂 ${details['file_name'] ?? ''} из «${details['from_folder'] ?? 'root'}» в «${details['to_folder'] ?? 'root'}»';
        case 'move_folder':
          return '📁 ${details['folder_name'] ?? ''} из «${details['from_folder'] ?? 'root'}» в «${details['to_folder'] ?? 'root'}»';
        case 'create_folder':
          return '📁 ${details['folder_name'] ?? ''}';
        case 'toggle_visibility':
          return '👁 ${details['file_name'] ?? ''} → ${details['new_visibility'] ?? ''}';
        case 'share':
          return '🔗 ${details['file_name'] ?? ''}';
        default:
          return '';
      }
    }
    return '';
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Фильтры', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                children: _actions.map((action) {
                  final isSelected = _filterAction == action;
                  return FilterChip(
                    label: Text(_actionLabels[action] ?? action),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        _filterAction = selected ? action : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'С даты (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => _filterDateFrom = v.isEmpty ? null : v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'По дату (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => _filterDateTo = v.isEmpty ? null : v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterAction = null;
                        _filterDateFrom = null;
                        _filterDateTo = null;
                        _filterUserId = null;
                      });
                      Navigator.pop(context);
                      _loadInitialData();
                    },
                    child: const Text('Сбросить'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadInitialData();
                    },
                    child: const Text('Применить'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История действий'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтры',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _logs.isEmpty && !_isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'Нет записей',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _logs.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final log = _logs[index];
                  final action = log['action'] as String? ?? '';
                  final icon = _actionIcons[action] ?? Icons.circle;
                  final label = _actionLabels[action] ?? action;
                  final nickname = log['nickname'] ?? 'Пользователь';
                  final createdAt = log['created_at'] ?? '';
                  final details = _formatDetails(log);
                  final ip = log['ip_address'] ?? '';

                  return ListTile(
                    leading: Icon(icon, color: _getActionColor(action)),
                    title: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname),
                        if (details.isNotEmpty)
                          Text(details, style: const TextStyle(fontSize: 12)),
                        Row(
                          children: [
                            Text(
                              formatRelativeDate(createdAt.toString()),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            if (ip.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text('IP: $ip', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    dense: false,
                  );
                },
              ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.green;
      case 'upload':
        return Colors.blue;
      case 'download':
        return Colors.indigo;
      case 'delete':
      case 'delete_folder':
        return Colors.red;
      case 'rename':
      case 'rename_folder':
        return Colors.orange;
      case 'move':
      case 'move_folder':
        return Colors.purple;
      case 'create_folder':
        return Colors.teal;
      case 'toggle_visibility':
        return Colors.amber;
      case 'share':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}