import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notification_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  
  IO.Socket? _socket;
  bool _connected = false;
  String? _currentToken;
  
  final NotificationService _notificationService = NotificationService();
  
  WebSocketService._();
  
  bool get isConnected => _connected;
  
  void connect(String token) {
    if (_socket?.connected == true) return;
    
    _currentToken = token;
    
    _socket = IO.io(
      'wss://90.156.171.36',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({
            'X-API-Token': token,
            'Host': 'gazonbaza.ru',
          })
          .setPath('/socket.io/')
          .enableAutoConnect()
          .setReconnectionDelay(5000)
          .setReconnectionAttempts(100)
          .build(),
    );
    
    _socket!.onConnect((_) {
      _connected = true;
      if (_socket != null) {
        print('WebSocket connected: ${_socket!.id}');
      }
    });
    
    _socket!.on('connected', (data) {
      print('WebSocket authenticated: $data');
    });
    
    _socket!.on('notification', (data) {
      print('Received notification: $data');
      
      final title = data['title'] ?? 'Уведомление';
      final body = data['body'] ?? '';
      String? payload;
      
      if (data['data'] != null && data['data'] is Map) {
        final d = data['data'] as Map<String, dynamic>;
        // Передаём file_id для навигации при тапе
        if (d['file_id'] != null) {
          payload = 'file_id=${d['file_id']}';
          if (d['folder_id'] != null) {
            payload += '&folder_id=${d['folder_id']}';
          }
        }
      }
      
      _notificationService.showNotification(
        title: title,
        body: body,
        payload: payload,
      );
    });
    
    _socket!.onDisconnect((_) {
      _connected = false;
      print('WebSocket disconnected');
    });
    
    _socket!.onError((error) {
      print('WebSocket error: $error');
    });
    
    _socket!.onReconnect((attempt) {
      print('WebSocket reconnected, attempt: $attempt');
    });
  }
  
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _currentToken = null;
  }
  
  void dispose() {
    disconnect();
  }
}