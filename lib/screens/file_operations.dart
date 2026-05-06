import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../widgets/file_icon.dart';
import '../utils/format_file_size.dart';
import 'package:share_plus/share_plus.dart';

mixin FileOperations {
  String get token;
  int get userId;
  bool get admin;

  Future<void> downloadFile(int fileId, String fileName, String fileType) async {
    final context = (this as dynamic).context as BuildContext;
    
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
                final success = await ApiService.downloadFile(token, fileId, fileName);

                if (!dialogContext.mounted || !(this as dynamic).mounted) return;

                if (success) {
                  final dir = Directory('/storage/emulated/0/Download');
                  File? foundFile;

                  if (await dir.exists()) {
                    final exactFile = File('${dir.path}/$fileName');
                    if (await exactFile.exists()) {
                      foundFile = exactFile;
                    } else {
                      final fileList = dir.listSync()
                          .whereType<File>()
                          .where((f) {
                            final name = f.uri.pathSegments.last;
                            return name == fileName || name.startsWith(fileName.replaceAll(RegExp(r'\.[^.]+$'), '')) && name.endsWith(fileName.split('.').last);
                          })
                          .toList()
                        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

                      if (fileList.isNotEmpty) {
                        foundFile = fileList.first;
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
                  Expanded(child: Text(hasError ? '❌ Ошибка' : (isCompleted ? '✅ Скачано' : 'Скачивание'))),
                  if (isCompleted || hasError)
                    IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasError) ...[
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 12),
                      Text('Не удалось скачать файл', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      SizedBox(height: 8),
                      Text(fileName, style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            downloadFile(fileId, fileName, fileType);
                          },
                          child: Text('Повторить'),
                        ),
                      ),
                    ] else if (!isCompleted) ...[
                      LinearProgressIndicator(value: progress > 0 ? progress : null),
                      SizedBox(height: 16),
                      Text('Загрузка...'),
                      Text(fileName, style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ] else ...[
                      Icon(getIconForType(fileType), size: 48, color: Theme.of(context).colorScheme.primary),
                      SizedBox(height: 12),
                      Text(fileName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          if (savedPath != null) {
                            try {
                              final result = await OpenFile.open(savedPath!);
                              if (result.type != ResultType.done) {
                                if ((this as dynamic).mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Не удалось открыть файл: ${result.message}')),
                                  );
                                }
                              }
                            } catch (e) {
                              if ((this as dynamic).mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                  child: Text('Сохранён в Downloads', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13)),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text('Нажмите, чтобы открыть', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
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

  IconData getIconForType(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('image') || type.contains('jpg') || type.contains('jpeg') || type.contains('png') || type.contains('webp') || type.contains('gif')) return Icons.image;
    if (type.contains('video') || type.contains('mp4') || type.contains('avi') || type.contains('mkv')) return Icons.videocam;
    if (type.contains('audio') || type.contains('mp3') || type.contains('wav') || type.contains('flac')) return Icons.audiotrack;
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('text') || type.contains('txt') || type.contains('log')) return Icons.text_snippet;
    if (type.contains('zip') || type.contains('rar') || type.contains('archive')) return Icons.archive;
    return Icons.insert_drive_file;
  }

  Future<void> deleteFile(int fileId, String fileName, int ownerId) async {
    final context = (this as dynamic).context as BuildContext;
    final canDelete = admin || ownerId == userId;
    if (!canDelete && (this as dynamic).mounted) {
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
    if (confirm == true && (this as dynamic).mounted) {
      final success = await ApiService.deleteFile(token, fileId);
      if (success && (this as dynamic).mounted) {
        (this as dynamic).loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Файл удалён')));
      } else if ((this as dynamic).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Ошибка удаления')));
      }
    }
  }

  Future<void> renameFile(dynamic file) async {
    final context = (this as dynamic).context as BuildContext;
    final ownerId = file['user_id'];
    final canRename = admin || ownerId == userId;
    if (!canRename && (this as dynamic).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Нет прав на переименование')));
      return;
    }
    final controller = TextEditingController(text: file['original_name']);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переименовать файл'),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(labelText: 'Новое имя', hintText: 'Введите новое имя файла')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('Переименовать')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != file['original_name'] && (this as dynamic).mounted) {
      final success = await ApiService.renameFile(token, file['id'], newName);
      if (success && (this as dynamic).mounted) {
        (this as dynamic).loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Файл переименован в "$newName"')));
      } else if ((this as dynamic).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка переименования')));
      }
    }
  }

  Future<void> moveFile(dynamic file) async {
    final context = (this as dynamic).context as BuildContext;
    final allFolders = await ApiService.getFolders(token);
    final chosenFolderId = await showDialog<int?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Переместить "${file['original_name']}" в папку'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, null), child: Text('📁 Корень')),
          ...allFolders.map((folder) => SimpleDialogOption(onPressed: () => Navigator.pop(context, folder['id']), child: Text('📁 ${folder['name']}'))),
        ],
      ),
    );
    if (chosenFolderId != null && (this as dynamic).mounted) {
      final success = await ApiService.moveFile(token, file['id'], chosenFolderId == 0 ? null : chosenFolderId);
      if (success && (this as dynamic).mounted) {
        (this as dynamic).loadContent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Файл перемещён')));
      } else if ((this as dynamic).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка перемещения')));
      }
    }
  }

  void showFileMenu(dynamic file) {
    final context = (this as dynamic).context as BuildContext;
    final ownerId = file['user_id'];
    final canDelete = admin || ownerId == userId;
    final isPublic = file['is_public'] == 1;
    final hasDescription = file['description'] != null && file['description'].toString().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (builderContext) {
        final bottomInset = MediaQuery.of(builderContext).viewInsets.bottom;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 70 + bottomInset),
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Превью изображения или иконка
                if ((this as dynamic).isImageType(file['file_type']))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 150,
                      width: 200,
                      color: Colors.grey.shade200,
                      child: CachedNetworkImage(
                        imageUrl: ApiService.thumbnailUrl(file['id']),
                        httpHeaders: {
                          'X-API-Token': token,
                          'Host': 'gazonbaza.ru',
                        },
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => FileIcon(
                          fileType: file['file_type'] ?? '',
                          size: 60,
                        ),
                      ),
                    ),
                  )
                else
                  FileIcon(fileType: file['file_type'] ?? '', size: 60),
                
                SizedBox(height: 12),
                
                // Имя файла
                Text(
                  file['original_name'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                
                // Описание (если есть)
                if (hasDescription) ...[
                  SizedBox(height: 8),
                  Text(
                    file['description'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                SizedBox(height: 10),
                
                // Информация о файле
                Text('Размер: ${file['file_size'] != null ? formatFileSize(file['file_size']) : 'неизвестно'}'),
                Text('Тип: ${file['file_type']}'),
                Text('Хозяин: ${file['owner_nickname']}'),
                Text('Дата: ${file['upload_date']}'),
                
                SizedBox(height: 8),
                
                // Переключатель видимости
                InkWell(
                  onTap: () async {
                    final success = await ApiService.toggleVisibility(token, file['id']);
                    if (success && (this as dynamic).mounted) {
                      Navigator.pop(context);
                      (this as dynamic).loadContent();
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
                
                // Кнопки действий
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      downloadFile(file['id'], file['original_name'], file['file_type'] ?? '');
                    },
                    icon: Icon(Icons.download),
                    label: Text('Скачать', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                
                // Поделиться
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      shareFile(file);
                    },
                    icon: Icon(Icons.share, color: Colors.teal),
                    label: Text('Поделиться', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.teal.shade100,
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
                      renameFile(file);
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
                      moveFile(file);
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
                        deleteFile(file['id'], file['original_name'], ownerId);
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
        );
      },
    );
  }

  Future<void> shareFile(dynamic file) async {
    final context = (this as dynamic).context as BuildContext;
    try {
      final shareUrl = await ApiService.getShareLink(token, file['id']);
      if (shareUrl == null) {
        if ((this as dynamic).mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Не удалось создать ссылку')),
          );
        }
        return;
      }
      await Share.share(
        'Посмотри файл "${file['original_name']}" в Кусочнице:\n$shareUrl',
        subject: file['original_name'],
      );
    } catch (e) {
      if ((this as dynamic).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке: $e')),
        );
      }
    }
  }


}