import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../utils/websocket_protobuf_parser.dart';
import 'storage_service.dart';

/// WebSocket服务
class WebSocketService {
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  bool _isConnected = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  /// 连接WebSocket
  Future<void> connect() async {
    if (_isConnected) return;
    try {
      final wsUrl = Uri.parse(ApiConfig.wsUrl);
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      await _login();
      _startHeartbeat();
      _isConnected = true;
      onConnected?.call();
      print('WebSocket连接成功');
    } catch (e) {
      print('WebSocket连接失败: $e');
      _isConnected = false;
    }
  }

  Future<void> _login() async {
    final token = StorageService.getToken();
    final userId = StorageService.getUserId();
    final deviceId = StorageService.getDeviceId();

    if (token == null || userId == null) {
      print('登录信息不完整');
      return;
    }

    final loginData = {
      'seq': DateTime.now().millisecondsSinceEpoch.toString(),
      'cmd': 'login',
      'data': {
        'userId': userId,
        'token': token,
        'platform': 'windows',
        'deviceId': deviceId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      },
    };

    _channel?.sink.add(jsonEncode(loginData));
    print('WebSocket登录请求已发送');
  }

  void _onData(dynamic message) {
    try {
      Uint8List? messageBytes;
      Map<String, dynamic>? data;

      if (message is Uint8List) {
        messageBytes = message;
      } else if (message is List<int>) {
        messageBytes = Uint8List.fromList(message);
      } else if (message is String) {
        try {
          data = jsonDecode(message) as Map<String, dynamic>?;
          if (data != null) {
            final cmd = data['cmd']?.toString() ?? '';
            print('WebSocket收到JSON消息: $cmd');
            if (cmd != 'heartbeat_ack') {
              _messageController.add(data);
            }
            return;
          }
        } catch (e) {
          messageBytes = Uint8List.fromList(message.codeUnits);
        }
      } else {
        print('WebSocket未知消息类型: ${message.runtimeType}');
        return;
      }

      if (messageBytes == null) {
        print('WebSocket无法转换消息为字节数组');
        return;
      }

      data = WebSocketProtobufParser.parsePushMessage(messageBytes) ??
           WebSocketProtobufParser.parseHeartbeatAck(messageBytes) ??
           WebSocketProtobufParser.parseDraftInput(messageBytes);

      if (data != null) {
        final cmd = data['cmd']?.toString() ?? '';
        print('WebSocket收到Protobuf消息: $cmd');

        if (cmd != 'heartbeat_ack') {
          _messageController.add(data);
        }
        return;
      }

      print('WebSocket无法解析消息，长度: ${messageBytes.length}');
    } catch (e, stackTrace) {
      print('WebSocket消息解析失败: $e');
      print('堆栈跟踪: $stackTrace');
    }
  }

  void _onError(error) {
    print('WebSocket错误: $error');
    _isConnected = false;
    onDisconnected?.call();
  }

  void _onDone() {
    print('WebSocket断开连接');
    _isConnected = false;
    _stopHeartbeat();
    onDisconnected?.call();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(ApiConfig.heartbeatInterval, (_) => _sendHeartbeat());
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeat() {
    if (!_isConnected) return;
    final heartbeatData = {
      'seq': DateTime.now().millisecondsSinceEpoch.toString(),
      'cmd': 'heartbeat',
      'data': {},
    };
    try {
      _channel?.sink.add(jsonEncode(heartbeatData));
    } catch (e) {
      print('发送心跳失败: $e');
    }
  }

  void sendInputInfo(String chatId, String input, String deviceId) {
    if (!_isConnected) return;
    final data = {
      'seq': DateTime.now().millisecondsSinceEpoch.toString(),
      'cmd': 'inputInfo',
      'data': {
        'chatId': chatId,
        'input': input,
        'deviceId': deviceId,
      },
    };
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      print('发送输入状态失败: $e');
    }
  }

  void dispose() {
    _messageController.close();
    disconnect();
    print('WebSocketService disposed');
  }

  void disconnect() {
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    print('WebSocket已断开');
  }
}

