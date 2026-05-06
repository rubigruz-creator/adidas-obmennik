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
    final isPublic = file['is_public'] == 1;
    final size = formatFileSize(file['file_size'] ?? 0);
    final date = formatRelativeDate(file['upload_date'] ?? '');
    final owner = file['owner_nickname'] ?? '';

    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              FileIcon(fileType: file['file_type'] ?? '', size: 36),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['original_name'] ?? 'Без имени',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(size, style: TextStyle(fontSize: 13, color: Colors.grey)),
                        SizedBox(width: 12),
                        Icon(
                          isPublic ? Icons.public : Icons.lock,
                          size: 14,
                          color: isPublic ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$owner • $date',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}