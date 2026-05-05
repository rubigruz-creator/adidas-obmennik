import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

  static Future<bool> uploadFile(String token, File file, String fileName, {bool isPublic = false, int? folderId}) async {
    final url = Uri.parse('$_baseUrl/upload.php');
    final request = http.MultipartRequest('POST', url);
    request.headers['X-API-Token'] = token;
    request.headers['Host'] = _host;
    request.files.add(await http.MultipartFile.fromPath('file', file.path, filename: fileName));
    request.fields['is_public'] = isPublic ? '1' : '0';
    if (folderId != null) {
      request.fields['folder_id'] = folderId.toString();
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
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return true;
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









}