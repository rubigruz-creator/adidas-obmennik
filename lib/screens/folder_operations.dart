import 'package:flutter/material.dart';
import '../services/api_service.dart';

mixin FolderOperations {
  String get token;
  int? get folderId;

  Future<void> createFolder() async {
    final context = (this as dynamic).context as BuildContext;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Новая папка'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: 'Название папки')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Создать')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final newFolderId = await ApiService.createFolder(token, name, parentId: folderId);
      if (newFolderId != null && (this as dynamic).mounted) {
        (this as dynamic).loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Папка "$name" создана')));
      } else if ((this as dynamic).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка создания папки')));
      }
    }
  }

  Future<void> renameFolder(dynamic folder) async {
    final context = (this as dynamic).context as BuildContext;
    final controller = TextEditingController(text: folder['name']);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переименовать папку'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: 'Новое имя')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Переименовать')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != folder['name']) {
      final success = await ApiService.renameFolder(token, folder['id'], newName);
      if (success && (this as dynamic).mounted) {
        (this as dynamic).loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Папка переименована')));
      } else if ((this as dynamic).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка')));
      }
    }
  }

  Future<void> deleteFolder(dynamic folder) async {
    final context = (this as dynamic).context as BuildContext;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить папку "${folder['name']}"?'),
        content: Text('Все файлы внутри будут перемещены в текущую папку. Продолжить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ApiService.deleteFolder(token, folder['id'], force: true);
      if (success && (this as dynamic).mounted) {
        (this as dynamic).loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Папка удалена')));
      } else if ((this as dynamic).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления')));
      }
    }
  }

  void showFolderMenu(dynamic folder) {
    final context = (this as dynamic).context as BuildContext;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(folder['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ElevatedButton.icon(onPressed: () { Navigator.pop(context); renameFolder(folder); }, icon: Icon(Icons.edit), label: Text('Переименовать')),
            SizedBox(height: 10),
            ElevatedButton.icon(onPressed: () { Navigator.pop(context); deleteFolder(folder); }, icon: Icon(Icons.delete, color: Colors.red), label: Text('Удалить', style: TextStyle(color: Colors.red)), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50)),
          ],
        ),
      ),
    );
  }
}