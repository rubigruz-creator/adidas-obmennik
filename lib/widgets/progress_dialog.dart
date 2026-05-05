import 'package:flutter/material.dart';
import '../models/cancel_token.dart';

class ProgressDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required Function(CancelToken) startOperation,
  }) async {
    final cancelToken = CancelToken();
    double progress = 0.0;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Запускаем операцию
            Future.microtask(() async {
              try {
                await startOperation(cancelToken);
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            });
            
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  SizedBox(height: 16),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      cancelToken.cancel();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Отмена'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // Упрощённый метод для загрузки
  static Future<void> showUploadProgress({
    required BuildContext context,
    required String fileName,
    required Future<bool> Function(CancelToken) uploadFunction,
  }) {
    return show(
      context: context,
      title: 'Загрузка: $fileName',
      startOperation: (cancelToken) async {
        await uploadFunction(cancelToken);
      },
    );
  }
  
  // Упрощённый метод для скачивания
  static Future<void> showDownloadProgress({
    required BuildContext context,
    required String fileName,
    required Future<bool> Function(CancelToken) downloadFunction,
  }) {
    return show(
      context: context,
      title: 'Скачивание: $fileName',
      startOperation: (cancelToken) async {
        await downloadFunction(cancelToken);
      },
    );
  }
}