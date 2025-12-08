import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../utils/websocket_protobuf_parser.dart';
import 'storage_service.dart';

/// WebSocket服务
class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  
  // 消息回调
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  /// 连接WebSocket
  Future<void> connect() async {
    try {
      final wsUrl = Uri.parse(ApiConfig.wsUrl);
      _channel = WebSocketChannel.connect(wsUrl);
      
      // 监听消息
      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
      
      // 登录
      await _login();
      
      // 启动心跳
      _startHeartbeat();
      
      _isConnected = true;
      onConnected?.call();
      
      print('WebSocket连接成功');
    } catch (e) {
      print('WebSocket连接失败: $e');
      _isConnected = false;
    }
  }

  /// 登录WebSocket
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

  /// 处理接收到的数据
  void _onData(dynamic message) {
    try {
      Uint8List? messageBytes;
      Map<String, dynamic>? data;
      
      // 转换为Uint8List
      if (message is Uint8List) {
        messageBytes = message;
      } else if (message is List<int>) {
        messageBytes = Uint8List.fromList(message);
      } else if (message is String) {
        // 尝试作为JSON解析（兼容性）
        try {
          data = jsonDecode(message) as Map<String, dynamic>?;
          if (data != null) {
            final cmd = data['cmd']?.toString() ?? '';
            print('WebSocket收到JSON消息: $cmd');
            
            if (cmd == 'heartbeat_ack') {
              return;
            }
            
            onMessageReceived?.call(data);
            return;
          }
        } catch (e) {
          // JSON解析失败，可能是Protobuf
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
      
      // 尝试解析为Protobuf
      // 先尝试解析为push_message
      data = WebSocketProtobufParser.parsePushMessage(messageBytes);
      
      if (data != null) {
        final cmd = data['cmd']?.toString() ?? '';
        print('WebSocket收到Protobuf消息: $cmd');
        
        if (cmd == 'heartbeat_ack') {
          return;
        }
        
        onMessageReceived?.call(data);
        return;
      }
      
      // 尝试解析为heartbeat_ack
      data = WebSocketProtobufParser.parseHeartbeatAck(messageBytes);
      if (data != null) {
        print('WebSocket收到心跳响应');
        return;
      }
      
      // 尝试解析为draft_input
      data = WebSocketProtobufParser.parseDraftInput(messageBytes);
      if (data != null) {
        final cmd = data['cmd']?.toString() ?? '';
        print('WebSocket收到草稿同步: $cmd');
        onMessageReceived?.call(data);
        return;
      }
      
      print('WebSocket无法解析消息，长度: ${messageBytes.length}');
      print('前16字节: ${messageBytes.sublist(0, messageBytes.length > 16 ? 16 : messageBytes.length)}');
      
    } catch (e, stackTrace) {
      print('WebSocket消息解析失败: $e');
      print('堆栈跟踪: $stackTrace');
    }
  }

  /// 处理错误
  void _onError(error) {
    print('WebSocket错误: $error');
    _isConnected = false;
    onDisconnected?.call();
  }

  /// 处理断开
  void _onDone() {
    print('WebSocket断开连接');
    _isConnected = false;
    _stopHeartbeat();
    onDisconnected?.call();
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(ApiConfig.heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 发送心跳
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

  /// 发送输入状态（草稿同步）
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

  /// 断开连接
  void disconnect() {
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    print('WebSocket已断开');
  }
}

