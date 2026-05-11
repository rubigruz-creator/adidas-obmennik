import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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