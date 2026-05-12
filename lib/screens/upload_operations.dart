import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class UploadTask {
  final String fileName;
  final Uint8List bytes;
  final bool isPublic;
  final String? description;
  final CancelToken cancelToken;
  double progress = 0.0;
  bool isCompleted = false;
  bool hasError = false;
  String? errorMessage;

  UploadTask({
    required this.fileName,
    required this.bytes,
    required this.isPublic,
    this.description,
    required this.cancelToken,
  });
}

mixin UploadOperations {
  String get token;
  int? get folderId;

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
          title: Text(hasError ? 'Ошибка' : (isCompleted ? 'Загружено' : 'Загрузка...')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompleted && !hasError) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Загрузка файла...'),
                const SizedBox(height: 8),
                Text(fileName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              if (isCompleted) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text('$fileName загружен!'),
              ],
              if (hasError) ...[
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(errorMessage ?? 'Неизвестная ошибка'),
              ],
              const SizedBox(height: 12),
              if (isCompleted || hasError)
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
            ],
          ),
        );
      },
    );

    if (isCompleted && (this as dynamic).mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
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
        token, bytes, fileName,
        isPublic: isPublic, folderId: folderId, description: description,
      );
    });
  }

  Future<bool> showVisibilityDialog() async {
    final context = (this as dynamic).context as BuildContext;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тип файла'),
        content: const Text('Сделать файл доступным для всех?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Личный')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Общий')),
        ],
      ),
    ) ?? false;
  }

  Future<String?> showDescriptionDialog() async {
    final context = (this as dynamic).context as BuildContext;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить описание к файлу?'),
        content: TextField(
          controller: controller, maxLines: 3, maxLength: 300,
          decoration: const InputDecoration(hintText: 'Не более 300 символов', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Пропустить')),
          TextButton(onPressed: () {
            final text = controller.text.trim();
            Navigator.pop(ctx, text.isEmpty ? null : text);
          }, child: const Text('Сохранить')),
        ],
      ),
    );
    return result;
  }

  Future<void> pickMultipleFiles() async {
    debugPrint('=== pickMultipleFiles: START ===');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);
      if (result == null || result.files.isEmpty) return;

      final isPublic = await showVisibilityDialog();
      final description = await showDescriptionDialog();
      final List<UploadTask> tasks = [];

      for (final pickedFile in result.files) {
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = pickedFile.bytes;
        } else {
          if (pickedFile.path != null) bytes = await File(pickedFile.path!).readAsBytes();
        }
        if (bytes == null || bytes.isEmpty) continue;
        tasks.add(UploadTask(
          fileName: pickedFile.name, bytes: bytes, isPublic: isPublic,
          description: description, cancelToken: CancelToken(),
        ));
      }

      if (tasks.isEmpty) throw Exception('Нет файлов для загрузки');
      await _showMultiUploadDialog(tasks);
    } catch (e) {
      debugPrint('Ошибка: $e');
    }
  }

  Future<void> _showMultiUploadDialog(List<UploadTask> tasks) async {
    final context = (this as dynamic).context as BuildContext;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => MultiUploadDialog(
        tasks: tasks,
        onStart: (task) => _startSingleMultiUpload(task, dialogContext),
        onCancel: (task) => task.cancelToken.cancel(),
        onClose: () => Navigator.pop(dialogContext),
      ),
    );
    if ((this as dynamic).mounted) (this as dynamic).loadContent();
  }

  void _startSingleMultiUpload(UploadTask task, BuildContext dialogContext) {
    debugPrint('_startSingleMultiUpload: START for ${task.fileName}');
    ApiService.uploadFileBytes(
      token, task.bytes, task.fileName,
      isPublic: task.isPublic, folderId: folderId, description: task.description,
    ).then((success) {
      debugPrint('_startSingleMultiUpload: DONE ${task.fileName}, success = $success');
      if (!dialogContext.mounted) return;
      task.isCompleted = true;
      task.progress = 1.0;
      if (!success) { task.hasError = true; task.errorMessage = 'Ошибка загрузки'; }
      (dialogContext as Element).markNeedsBuild();
    }).catchError((e) {
      debugPrint('_startSingleMultiUpload: ERROR ${task.fileName} = $e');
      if (!dialogContext.mounted) return;
      task.isCompleted = true;
      task.hasError = true;
      task.errorMessage = e.toString();
      (dialogContext as Element).markNeedsBuild();
    });
  }

  Future<void> pickAnyFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false, type: FileType.any);
      if (result == null || result.files.isEmpty) return;
      final pickedFile = result.files.first;
      Uint8List? bytes;
      if (kIsWeb) { bytes = pickedFile.bytes; } else { if (pickedFile.path != null) bytes = await File(pickedFile.path!).readAsBytes(); }
      if (bytes == null || bytes.isEmpty) throw Exception('Не удалось прочитать файл');
      final description = await showDescriptionDialog();
      final isPublic = await showVisibilityDialog();
      await uploadFileBytes(bytes, pickedFile.name, isPublic, description: description);
    } catch (e) { debugPrint('Ошибка: $e'); }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      final description = await showDescriptionDialog();
      final isPublic = await showVisibilityDialog();
      await uploadFileBytes(bytes, pickedFile.name, isPublic, description: description);
    } catch (e) { debugPrint('Ошибка: $e'); }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      final description = await showDescriptionDialog();
      final isPublic = await showVisibilityDialog();
      await uploadFileBytes(bytes, pickedFile.name, isPublic, description: description);
    } catch (e) { debugPrint('Ошибка: $e'); }
  }
}

class MultiUploadDialog extends StatefulWidget {
  final List<UploadTask> tasks;
  final Function(UploadTask) onStart;
  final Function(UploadTask) onCancel;
  final VoidCallback onClose;

  const MultiUploadDialog({required this.tasks, required this.onStart, required this.onCancel, required this.onClose});

  @override
  State<MultiUploadDialog> createState() => MultiUploadDialogState();
}

class MultiUploadDialogState extends State<MultiUploadDialog> {
  int _completedCount = 0;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    for (final task in widget.tasks) { widget.onStart(task); }
    _startProgressUpdater();
  }

  void _startProgressUpdater() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return false;
      int completed = widget.tasks.where((t) => t.isCompleted).length;
      int errors = widget.tasks.where((t) => t.hasError).length;
      setState(() { _completedCount = completed; _errorCount = errors; });
      return _completedCount < widget.tasks.length;
    });
  }

  bool get _allDone => _completedCount >= widget.tasks.length;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_allDone ? (_errorCount > 0 ? 'Загружено с ошибками' : 'Всё загружено') : 'Загрузка файлов...'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _allDone
                    ? '${_completedCount - _errorCount} из ${widget.tasks.length} успешно'
                    : 'Загружено $_completedCount из ${widget.tasks.length}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (!_allDone)
              LinearProgressIndicator(value: widget.tasks.isEmpty ? 0 : (_completedCount / widget.tasks.length)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.tasks.length,
                itemBuilder: (ctx, index) => _buildFileItem(widget.tasks[index]),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_allDone)
          ElevatedButton(onPressed: widget.onClose, child: const Text('OK'))
        else
          TextButton(
            onPressed: () {
              for (final task in widget.tasks) { if (!task.isCompleted) widget.onCancel(task); }
              widget.onClose();
            },
            child: const Text('Отменить всё'),
          ),
      ],
    );
  }

  Widget _buildFileItem(UploadTask task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (task.hasError)
            const Icon(Icons.error, color: Colors.red, size: 20)
          else if (task.isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, value: task.progress)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.fileName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                if (!task.isCompleted && !task.hasError)
                  Text('${(task.progress * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (task.hasError)
                  Text(task.errorMessage ?? 'Ошибка', style: const TextStyle(fontSize: 11, color: Colors.red), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!task.isCompleted)
            IconButton(
              icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
              onPressed: () {
                widget.onCancel(task);
                setState(() { task.isCompleted = true; task.hasError = true; task.errorMessage = 'Отменено'; });
              },
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}