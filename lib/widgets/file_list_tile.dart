import 'package:flutter/material.dart';
import '../utils/format_file_size.dart';
import '../utils/format_date.dart';
import 'file_icon.dart';

class FileListTile extends StatelessWidget {
  final Map<String, dynamic> file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const FileListTile({
    Key? key,
    required this.file,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isNew = file['is_new'] == true;
    return ListTile(
      leading: Stack(
        children: [
          FileIcon(fileType: file['file_type'] ?? '', size: 40),
          if (isNew)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      title: Text(file['original_name'] ?? 'Без имени', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatFileSize(file['file_size'] ?? 0)),
      trailing: Text(formatRelativeDate(file['upload_date'] ?? '')),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}