import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Класс для отмены операций
class CancelToken {
  bool isCancelled = false;
  
  void cancel() {
    isCancelled = true;
  }
}

class ApiService {
  static const String _baseUrl = 'https://90.156.171.36';
  static const String _host = 'gazonbaza.ru';

  static Future<http.Response> _post(String token, String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final request = http.Request('POST', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(data);
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  static Future<Map<String, dynamic>> getFolderContent(String token, {int? folderId, String search = ''}) async {
    Uri url;
    if (folderId != null) {
      url = Uri.parse('$_baseUrl/list_files.php?folder_id=$folderId&search=$search');
    } else {
      url = Uri.parse('$_baseUrl/list_files.php?search=$search');
    }
    final request = http.Request('GET', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'folders': data['folders'] ?? [],
        'files': data['files'] ?? [],
      };
    } else {
      throw Exception('Failed to load content');
    }
  }

  static Future<List<dynamic>> getFiles(String token, {String search = '', int? folderId}) async {
    final content = await getFolderContent(token, folderId: folderId, search: search);
    return content['files'];
  }

  static Future<bool> uploadFile(String token, File file, String fileName, {bool isPublic = false, int? folderId,
  String? description,}) async {
    final url = Uri.parse('$_baseUrl/upload.php');
    final request = http.MultipartRequest('POST', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: fileName));
    request.fields['is_public'] = isPublic ? '1' : '0';
    if (folderId != null) {
      request.fields['folder_id'] = folderId.toString();
    }
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }   
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response.statusCode == 200;
  }

  static Future<bool> downloadFile(String token, int fileId, String fileName) async {
    final url = Uri.parse('$_baseUrl/download.php?id=$fileId');
    final request = http.Request('GET', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      try {
        // Сохраняем в общедоступную папку Downloads
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        // Уникальное имя если файл уже существует
        String filePath = '${directory.path}/$fileName';
        int counter = 1;
        while (await File(filePath).exists()) {
          final dotIndex = fileName.lastIndexOf('.');
          final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
          final ext = dotIndex > 0 ? fileName.substring(dotIndex) : '';
          filePath = '${directory.path}/${baseName}_$counter$ext';
          counter++;
        }
        
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return true;
      } catch (e) {
        // Если нет доступа — сохраняем в папку приложения
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          return true;
        }
      }
    }
    return false;
  }


  static Future<bool> deleteFile(String token, int fileId) async {
    final response = await _post(token, '/delete.php', {'id': fileId});
    return response.statusCode == 200;
  }

  static Future<bool> renameFile(String token, int fileId, String newName) async {
    final response = await _post(token, '/rename.php', {'id': fileId, 'new_name': newName});
    return response.statusCode == 200;
  }

  static Future<bool> toggleVisibility(String token, int fileId) async {
    final response = await _post(token, '/toggle_visibility.php', {'id': fileId});
    return response.statusCode == 200;
  }

  // Folders API
  static Future<int?> createFolder(String token, String name, {int? parentId}) async {
    final response = await _post(token, '/create_folder.php', {
      'name': name,
      'parent_id': parentId,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['folder_id'];
    }
    return null;
  }

  static Future<bool> deleteFolder(String token, int folderId, {bool force = false}) async {
    final response = await _post(token, '/delete_folder.php', {
      'id': folderId,
      'force': force,
    });
    return response.statusCode == 200;
  }

  static Future<bool> renameFolder(String token, int folderId, String newName) async {
    final response = await _post(token, '/rename_folder.php', {
      'id': folderId,
      'new_name': newName,
    });
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getFolders(String token, {int? parentId}) async {
    Uri url;
    if (parentId != null) {
      url = Uri.parse('$_baseUrl/list_folders.php?parent_id=$parentId');
    } else {
      url = Uri.parse('$_baseUrl/list_folders.php');
    }
    final request = http.Request('GET', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['folders'];
    }
    return [];
  }

  static Future<bool> moveFile(String token, int fileId, int? folderId) async {
    final response = await _post(token, '/move_file.php', {
      'file_id': fileId,
      'folder_id': folderId,
    });
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> register(String phone, String password, String nickname, String fullName, String position) async {
    final url = Uri.parse('$_baseUrl/register.php');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Host': _host,
      },
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'nickname': nickname,
        'full_name': fullName,
        'position': position,
      }),
    );
    return jsonDecode(response.body);
  }     

  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final url = Uri.parse('$_baseUrl/login.php');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Host': _host,
      },
      body: jsonEncode({
        'phone': phone,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Profile API
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final url = Uri.parse('$_baseUrl/profile.php');
    final request = http.Request('GET', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
    }
    throw Exception('Failed to load profile');
  }

  static Future<Map<String, dynamic>> updateProfile(String token, {
    String? nickname,
    String? fullName,
    String? position,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (fullName != null) body['full_name'] = fullName;
    if (position != null) body['position'] = position;
    
    final response = await _post(token, '/profile.php', body);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
    }
    throw Exception('Failed to update profile');
  }

  // ============ МЕТОДЫ С ПРОГРЕССОМ ============
  
  // Загрузка файла с прогрессом (упрощённая версия с симуляцией)
  static Future<bool> uploadFileWithProgress(
    String token,
    File file,
    String fileName, {
    required Function(double) onProgress,
    bool isPublic = false,
    int? folderId,
    CancelToken? cancelToken,
  }) async {
    // Симулируем прогресс от 0 до 0.9
    int step = 0;
    final timer = Stream.periodic(Duration(milliseconds: 100), (_) {
      if (cancelToken?.isCancelled == true) return;
      step += 5;
      if (step <= 90) {
        onProgress(step / 100);
      }
    });
    
    final subscription = timer.listen((_) {});
    
    try {
      final result = await uploadFile(token, file, fileName, 
        isPublic: isPublic, 
        folderId: folderId,
      );
      
      subscription.cancel();
      
      if (result && (cancelToken?.isCancelled != true)) {
        onProgress(1.0);
      }
      
      return result;
    } catch (e) {
      subscription.cancel();
      rethrow;
    }
  }
  
  // Скачивание файла с прогрессом
  static Future<bool> downloadFileWithProgress(
    String token,
    int fileId,
    String fileName, {
    required Function(double) onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = Uri.parse('$_baseUrl/download.php?id=$fileId');
    final request = http.Request('GET', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    
    final streamedResponse = await request.send();
    
    if (cancelToken?.isCancelled == true) return false;
    
    final contentLength = streamedResponse.contentLength;
    final directory = await getDownloadsDirectory();
    if (directory == null) return false;
    
    final file = File('${directory.path}/$fileName');
    final sink = file.openWrite();
    int receivedBytes = 0;
    
    try {
      await for (final chunk in streamedResponse.stream) {
        if (cancelToken?.isCancelled == true) {
          await sink.close();
          await file.delete();
          return false;
        }
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (contentLength != null) {
          onProgress(receivedBytes / contentLength);
        }
      }
      await sink.close();
      onProgress(1.0);
      return true;
    } catch (e) {
      await sink.close();
      await file.delete();
      rethrow;
    }
  }


  // Скачивание файла с прогрессом (простая версия)
  static Future<bool> downloadFileSimple(
    String token,
    int fileId,
    String fileName, {
    required Function(double) onProgress,
  }) async {
    final url = Uri.parse('$_baseUrl/download.php?id=$fileId');
    final request = http.Request('GET', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    
    final streamedResponse = await request.send();
    final contentLength = streamedResponse.contentLength;
    
    try {
      // Сохраняем в общедоступную папку Downloads
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = File('${directory.path}/$fileName');
      final sink = file.openWrite();
      int receivedBytes = 0;
      
      await streamedResponse.stream.listen(
        (chunk) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (contentLength != null) {
            onProgress(receivedBytes / contentLength);
          }
        },
        onDone: () async {
          await sink.close();
          onProgress(1.0);
        },
        onError: (error) async {
          await sink.close();
          throw error;
        },
      ).asFuture();
      
      return true;
    } catch (e) {
      // Fallback
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final file = File('${directory.path}/$fileName');
        final bytes = await streamedResponse.stream.toList();
        await file.writeAsBytes(bytes.expand((x) => x).toList());
        onProgress(1.0);
        return true;
      }
      return false;
    }
  }


  static String thumbnailUrl(int fileId) => '$_baseUrl/download.php?id=$fileId&thumbnail=1';

}