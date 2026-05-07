import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/format_file_size.dart';
import '../utils/format_date.dart';
import '../services/api_service.dart';
import 'file_icon.dart';

class FileCard extends StatelessWidget {
  final Map<String, dynamic> file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String apiToken;

  const FileCard({
    Key? key,
    required this.file,
    required this.onTap,
    this.onLongPress,
    required this.apiToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPublic = file['is_public'] == 1;
    final size = formatFileSize(file['file_size'] ?? 0);
    final date = formatRelativeDate(file['upload_date'] ?? '');
    final isImage = _isImageType(file['file_type'] ?? '');
    final isNew = file['is_new'] == true;   // <-- флаг новизны

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: ApiService.thumbnailUrl(file['id']),
                        httpHeaders: {
                          'X-API-Token': apiToken,
                          'Host': 'gazonbaza.ru',
                        },
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => FileIcon(
                          fileType: file['file_type'] ?? '',
                          size: 40,
                        ),
                      ),
                    )
                  else
                    FileIcon(fileType: file['file_type'] ?? '', size: 40),
                  SizedBox(height: 8),
                  Text(
                    file['original_name'] ?? 'Без имени',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(size, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        isPublic ? Icons.public : Icons.lock,
                        size: 16,
                        color: isPublic ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isNew)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isImageType(String type) {
    final t = type.toLowerCase();
    return t.contains('jpg') ||
        t.contains('jpeg') ||
        t.contains('png') ||
        t.contains('webp') ||
        t.contains('gif') ||
        t.contains('bmp');
  }
}