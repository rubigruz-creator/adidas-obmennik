import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

/// Модель одной задачи загрузки
class _UploadTask {
  final String fileName;
  final Uint8List bytes;
  final bool isPublic;
  final String? description;
  final CancelToken cancelToken;
  double progress;
  bool isCompleted;
  bool hasError;
  String? errorMessage;

  _UploadTask({
    required this.fileName,
    required this.bytes,
    required this.isPublic,
    this.description,
    required this.cancelToken,
    this.progress = 0.0,
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
  });
}

mixin UploadOperations {
  String get token;
  int? get folderId;

  // ============ ОДИНОЧНАЯ ЗАГРУЗКА (СУЩЕСТВУЮЩАЯ — НЕ ТРОГАЕМ) ============

  Future<void> _showUploadDialog(String fileName, Future<bool> Function() uploadTask) async {
    final context = (this as dynamic).context as BuildContext;
    bool isCompleted = false;
    bool hasError = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _startUpload(dialogContext, uploadTask, (completed, error, msg) {
          isCompleted = completed;
          hasError = error;
          errorMessage = msg;
        });

        return AlertDialog(
          title: Text(hasError ? '❌ Ошибка' : (isCompleted ? '✅ Загружено' : 'Загрузка...')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompleted && !hasError) ...[
                LinearProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка файла...'),
                SizedBox(height: 8),
                Text(fileName, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              if (isCompleted) ...[
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text('$fileName загружен!'),
              ],
              if (hasError) ...[
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 12),
                Text(errorMessage ?? 'Неизвестная ошибка'),
              ],
              SizedBox(height: 12),
              if (isCompleted || hasError)
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('OK'),
                ),
            ],
          ),
        );
      },
    );

    if (isCompleted && (this as dynamic).mounted) {
      Future.delayed(Duration(milliseconds: 500), () {
        if ((this as dynamic).mounted) {
          (this as dynamic).loadContent();
        }
      });
    }
  }

  void _startUpload(
    BuildContext dialogContext,
    Future<bool> Function() uploadTask,
    void Function(bool completed, bool error, String? msg) onResult,
  ) {
    uploadTask().then((success) {
      if (!dialogContext.mounted) return;
      if (success) {
        onResult(true, false, null);
      } else {
        onResult(false, true, 'Ошибка загрузки');
      }
      (dialogContext as Element).markNeedsBuild();
    }).catchError((e) {
      if (!dialogContext.mounted) return;
      onResult(false, true, e.toString());
      (dialogContext as Element).markNeedsBuild();
    });
  }

  Future<void> uploadFileBytes(Uint8List bytes, String fileName, bool isPublic, {String? description}) async {
    await _showUploadDialog(fileName, () async {
      return await ApiService.uploadFileBytes(
        token,
        bytes,
        fileName,
        isPublic: isPublic,
        folderId: folderId,
        description: description,
      );
    });
  }

  Future<bool> showVisibilityDialog() async {
    final context = (this as dynamic).context as BuildContext;
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

  Future<String?> showDescriptionDialog() async {
    final context = (this as dynamic).context as BuildContext;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Добавить описание к файлу?'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(hintText: 'Не более 300 символов', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text('Пропустить')),
            TextButton(onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isEmpty ? null : text);
            }, child: Text('Сохранить')),
          ],
        );
      },
    );
    return result;
  }

  // ============ МНОЖЕСТВЕННАЯ ЗАГРУЗКА (НОВОЕ) ============

  /// Основной метод для выбора нескольких файлов
  Future<void> pickMultipleFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // <-- ключевое изменение
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;

      // Спрашиваем видимость и описание ОДИН раз для всех файлов
      final isPublic = await showVisibilityDialog();
      final description = await showDescriptionDialog();

      // Формируем список задач
      final List<_UploadTask> tasks = [];

      for (final pickedFile in result.files) {
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = pickedFile.bytes;
        } else {
          if (pickedFile.path != null) {
            bytes = await File(pickedFile.path!).readAsBytes();
          }
        }
        if (bytes == null || bytes.isEmpty) {
          print('Не удалось прочитать файл: ${pickedFile.name}');
          continue;
        }

        tasks.add(_UploadTask(
          fileName: pickedFile.name,
          bytes: bytes,
          isPublic: isPublic,
          description: description,
          cancelToken: CancelToken(),
        ));
      }

      if (tasks.isEmpty) {
        throw Exception('Нет файлов для загрузки');
      }

      // Показываем диалог очереди
      await _showMultiUploadDialog(tasks);
    } catch (e) {
      print('Ошибка при выборе файлов: $e');
    }
  }

  /// Диалог с очередью загрузки нескольких файлов
  Future<void> _showMultiUploadDialog(List<_UploadTask> tasks) async {
    final context = (this as dynamic).context as BuildContext;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _MultiUploadDialog(
          tasks: tasks,
          onStart: (task) => _startSingleMultiUpload(task),
          onCancel: (task) => task.cancelToken.cancel(),
          onClose: () => Navigator.pop(dialogContext),
          parentContext: context,
        );
      },
    );

    // Обновляем содержимое после закрытия диалога
    if ((this as dynamic).mounted) {
      (this as dynamic).loadContent();
    }
  }

  /// Запуск одной задачи из множественной загрузки
  void _startSingleMultiUpload(_UploadTask task) {
    ApiService.uploadFileBytesWithProgress(
      token,
      task.bytes,
      task.fileName,
      onProgress: (progress) {
        task.progress = progress;
        // Обновление UI происходит через StatefulWidget внутри диалога
      },
      isPublic: task.isPublic,
      folderId: folderId,
      cancelToken: task.cancelToken,
      description: task.description,
    ).then((success) {
      task.isCompleted = true;
      task.progress = 1.0;
      if (!success) {
        task.hasError = true;
        task.errorMessage = 'Ошибка загрузки';
      }
    }).catchError((e) {
      task.isCompleted = true;
      task.hasError = true;
      task.errorMessage = e.toString();
    });
  }

  // ============ СУЩЕСТВУЮЩИЕ МЕТОДЫ (НЕ ТРОГАЕМ) ============

  Future<void> pickAnyFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false, type: FileType.any);
      if (result == null || result.files.isEmpty) return;
      final pickedFile = result.files.first;

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = pickedFile.bytes;
      } else {
        if (pickedFile.path != null) bytes = await File(pickedFile.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) throw Exception('Не удалось прочитать файл');

      final description = await showDescriptionDialog();
      final isPublic = await showVisibilityDialog();
      await uploadFileBytes(bytes, pickedFile.name, isPublic, description: description);
    } catch (e) {
      print('Ошибка при выборе файла: $e');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      final description = await showDescriptionDialog();
      final isPublic = await showVisibilityDialog();
      await uploadFileBytes(bytes, pickedFile.name, isPublic, description: description);
    } catch (e) {
      print('Ошибка при выборе изображения: $e');
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      final description = await showDescriptionDialog();
      final isPublic = await showVisibilityDialog();
      await uploadFileBytes(bytes, pickedFile.name, isPublic, description: description);
    } catch (e) {
      print('Ошибка при фотографировании: $e');
    }
  }
}

/// Виджет диалога множественной загрузки
class _MultiUploadDialog extends StatefulWidget {
  final List<_UploadTask> tasks;
  final Function(_UploadTask) onStart;
  final Function(_UploadTask) onCancel;
  final VoidCallback onClose;
  final BuildContext parentContext;

  const _MultiUploadDialog({
    required this.tasks,
    required this.onStart,
    required this.onCancel,
    required this.onClose,
    required this.parentContext,
  });

  @override
  State<_MultiUploadDialog> createState() => _MultiUploadDialogState();
}

class _MultiUploadDialogState extends State<_MultiUploadDialog> {
  bool _allStarted = false;
  int _completedCount = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    _startAll();
  }

  void _startAll() {
    _allStarted = true;
    for (final task in widget.tasks) {
      widget.onStart(task);
    }
    // Периодически обновляем UI
    _startProgressUpdater();
  }

  void _startProgressUpdater() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(Duration(milliseconds: 150));
      if (!mounted) return false;

      int completed = widget.tasks.where((t) => t.isCompleted).length;
      int errors = widget.tasks.where((t) => t.hasError).length;

      if (completed != _completedCount || errors != _errorCount) {
        setState(() {
          _completedCount = completed;
          _errorCount = errors;
        });
      }

      // Продолжаем, пока не завершатся все
      return _completedCount < widget.tasks.length;
    });
  }

  bool get _allDone => _completedCount >= widget.tasks.length;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_allDone 
          ? (_errorCount > 0 ? '⚠️ Загружено с ошибками' : '✅ Всё загружено')
          : 'Загрузка файлов...'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Общая информация
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _allDone
                    ? '${_completedCount - _errorCount} из ${widget.tasks.length} успешно'
                    : 'Загружено ${_completedCount} из ${widget.tasks.length}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (!_allDone)
              LinearProgressIndicator(
                value: widget.tasks.isEmpty ? 0 : (_completedCount / widget.tasks.length),
              ),
            SizedBox(height: 12),
            // Список файлов
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.tasks.length,
                itemBuilder: (ctx, index) {
                  final task = widget.tasks[index];
                  return _buildFileItem(task);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_allDone)
          ElevatedButton(
            onPressed: widget.onClose,
            child: Text('OK'),
          )
        else
          TextButton(
            onPressed: () {
              // Отмена всех незавершённых
              for (final task in widget.tasks) {
                if (!task.isCompleted) {
                  widget.onCancel(task);
                }
              }
              widget.onClose();
            },
            child: Text('Отменить всё'),
          ),
      ],
    );
  }

  Widget _buildFileItem(_UploadTask task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Иконка статуса
          if (task.hasError)
            Icon(Icons.error, color: Colors.red, size: 20)
          else if (task.isCompleted)
            Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: task.progress,
              ),
            ),
          SizedBox(width: 8),
          // Имя файла и прогресс
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.fileName,
                  style: TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!task.isCompleted && !task.hasError)
                  Text(
                    '${(task.progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                if (task.hasError)
                  Text(
                    task.errorMessage ?? 'Ошибка',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Кнопка отмены (только для незавершённых)
          if (!task.isCompleted)
            IconButton(
              icon: Icon(Icons.cancel, size: 20, color: Colors.grey),
              onPressed: () {
                widget.onCancel(task);
                setState(() {
                  task.isCompleted = true;
                  task.hasError = true;
                  task.errorMessage = 'Отменено';
                });
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }
}