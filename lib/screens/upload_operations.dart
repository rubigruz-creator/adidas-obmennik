import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

mixin UploadOperations {
  String get token;
  int? get folderId;

  Timer? uploadProgressTimer;

  Future<void> uploadFile(File file, String fileName, bool isPublic, {String? description}) async {
    final context = (this as dynamic).context as BuildContext;
    double progress = 0.0;
    uploadProgressTimer?.cancel();
    uploadProgressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!(this as dynamic).mounted) { timer.cancel(); return; }
      if (progress < 0.95) {
        progress += 0.05;
        if ((this as dynamic).mounted) (this as dynamic).setState(() {});
      } else if (progress >= 0.95 && timer.isActive) {
        timer.cancel();
      }
    });
    final success = await ApiService.uploadFile(token, file, fileName, isPublic: isPublic, folderId: folderId, description: description);
    uploadProgressTimer?.cancel();
    uploadProgressTimer = null;
    if (success && (this as dynamic).mounted) {
      progress = 1.0;
      (this as dynamic).setState(() {});
      (this as dynamic).loadContent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $fileName загружен!')));
    } else if ((this as dynamic).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка загрузки')));
    }
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
            decoration: InputDecoration(
              hintText: 'Не более 300 символов',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('Пропустить'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.pop(ctx, text.isEmpty ? null : text);
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> pickAnyFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final pickedFile = result.files.first;
    File file;

    if (kIsWeb) {
      if (pickedFile.bytes != null) {
        final tempDir = Directory.systemTemp;
        final tempPath = '${tempDir.path}/${pickedFile.name}';
        file = File(tempPath);
        await file.writeAsBytes(pickedFile.bytes!);
      } else {
        return;
      }
    } else {
      if (pickedFile.path != null) {
        file = File(pickedFile.path!);
      } else {
        return;
      }
    }

    final description = await showDescriptionDialog();
    final isPublic = await showVisibilityDialog();
    await uploadFile(file, pickedFile.name, isPublic, description: description);
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file;
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/${pickedFile.name}';
      file = File(tempPath);
      await file.writeAsBytes(bytes);
    } else {
      file = File(pickedFile.path);
    }

    final description = await showDescriptionDialog();
    final isPublic = await showVisibilityDialog();
    await uploadFile(file, pickedFile.name, isPublic, description: description);
  }

  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    File file;
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/${pickedFile.name}';
      file = File(tempPath);
      await file.writeAsBytes(bytes);
    } else {
      file = File(pickedFile.path);
    }

    final description = await showDescriptionDialog();
    final isPublic = await showVisibilityDialog();
    await uploadFile(file, pickedFile.name, isPublic, description: description);
  }
}