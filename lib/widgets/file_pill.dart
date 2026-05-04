import 'package:flutter/material.dart';

class FilePill extends StatelessWidget {
  final dynamic file;
  final int index;
  final VoidCallback onTap;

  const FilePill({
    Key? key,
    required this.file,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  Color _getColorForFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return Colors.green;
    if (['pdf'].contains(ext)) return Colors.red;
    if (['doc', 'docx', 'txt'].contains(ext)) return Colors.blue;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Colors.purple;
    if (['mp3', 'wav'].contains(ext)) return Colors.pink;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final isRecent = index < 3;
    final fontSize = isRecent ? 18.0 : 14.0;
    final padding = isRecent ? 16.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
        decoration: BoxDecoration(
          color: _getColorForFile(file['original_name']),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['original_name'],
                    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${file['size_mb']} MB • ${file['owner_nickname']}',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(file['is_public'] == 1 ? Icons.public : Icons.lock, size: 18),
          ],
        ),
      ),
    );
  }
}