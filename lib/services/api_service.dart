import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../utils/protobuf_parser.dart';
import '../utils/protobuf_encoder.dart';
import 'storage_service.dart';

/// API服务
class ApiService {
  /// 获取通用请求头
  static Map<String, String> _getHeaders({
    bool includeToken = true,
    bool isProtobuf = false,
  }) {
    final headers = <String, String>{};
    
    if (isProtobuf) {
      headers['Content-Type'] = 'application/x-protobuf';
      headers['Accept'] = 'application/x-protobuf';
    } else {
      headers['Content-Type'] = 'application/json';
    }
    
    if (includeToken) {
      final token = StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['token'] = token;
      }
    }
    
    return headers;
  }

  /// 解析响应（自动处理JSON和Protobuf）
  static dynamic _parseResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    
    if (contentType.contains('application/json')) {
      // JSON 响应
      return jsonDecode(response.body);
    } else if (contentType.contains('application/x-protobuf') || 
               contentType.contains('application/protobuf') ||
               contentType.contains('application/octet-stream')) {
      // Protobuf 响应 - 直接返回字节数组，由具体方法解析
      return response.bodyBytes;
    } else {
      // 默认尝试 JSON
      try {
        return jsonDecode(response.body);
      } catch (e) {
        // 如果 JSON 失败，可能是 Protobuf
        return response.bodyBytes;
      }
    }
  }

  /// 邮箱密码登录
  static Future<LoginResponse> emailLogin({
    required String email,
    required String password,
    String? deviceId,
    String platform = 'windows',
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userEmailLogin}');
      final body = {
        'email': email,
        'password': password,
        'deviceId': deviceId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'platform': platform,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(includeToken: false),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      return LoginResponse.fromJson(data);
    } catch (e) {
      return LoginResponse(
        code: -1,
        msg: '登录失败: ${e.toString()}',
      );
    }
  }

  /// 获取用户信息（Protobuf格式）
  static Future<UserModel?> getUserInfo() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userInfo}');
      final response = await http.get(
        url,
        headers: _getHeaders(isProtobuf: true),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        
        // 如果是 Protobuf 格式（字节数组）
        if (data is Uint8List) {
          final parsed = parseUserInfo(data);
          if (parsed != null) {
            final status = parsed['status'] as Map<String, dynamic>?;
            final userData = parsed['data'] as Map<String, dynamic>?;
            
            if (status != null && status['code'] == 1 && userData != null) {
              return UserModel.fromJson(userData);
            }
          }
        }
        
        // 如果是 JSON 格式
        if (data is Map<String, dynamic>) {
          if (data['code'] == 1 && data['data'] != null) {
            return UserModel.fromJson(data['data']);
          }
        }
      }
      return null;
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  /// 获取会话列表（Protobuf格式）
  static Future<List<ConversationModel>> getConversationList() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.conversationList}');
      final response = await http.post(
        url,
        headers: _getHeaders(isProtobuf: true),
        body: Uint8List(0), // 空的 protobuf body
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        
        // 如果是 Protobuf 格式（字节数组）
        if (data is Uint8List) {
          final parsed = parseConversationList(data);
          if (parsed != null) {
            final status = parsed['status'] as Map<String, dynamic>?;
            final conversationList = parsed['data'] as List<dynamic>?;
            
            if (status != null && status['code'] == 1 && conversationList != null) {
              return conversationList
                  .map((item) => ConversationModel.fromJson(item))
                  .toList();
            }
          }
        }
        
        // 兼容 JSON 格式
        if (data is Map<String, dynamic>) {
          if (data['code'] == 1 && data['data'] != null) {
            final List<dynamic> list = data['data'] is List 
                ? data['data'] 
                : (data['data']['data'] ?? []);
            return list.map((item) => ConversationModel.fromJson(item)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('获取会话列表失败: $e');
      return [];
    }
  }

  /// 获取消息列表（Protobuf格式）
  static Future<List<MessageModel>> getMessageList({
    required String chatId,
    required int chatType,
    int msgCount = 30,
    String? msgId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listMessage}');
      
      // 使用 Protobuf 编码请求
      final bodyBytes = encodeListMessage(
        chatId: chatId,
        chatType: chatType,
        msgCount: msgCount,
        msgId: msgId,
      );

      final response = await http.post(
        url,
        headers: _getHeaders(isProtobuf: true),
        body: bodyBytes,
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        
        // 如果是 Protobuf 格式（字节数组）
        if (data is Uint8List) {
          final parsed = parseMessageList(data);
          if (parsed != null) {
            final status = parsed['status'] as Map<String, dynamic>?;
            final msgList = parsed['msg'] as List<dynamic>?;
            
            if (status != null && status['code'] == 1 && msgList != null) {
              return msgList
                  .map((item) => MessageModel.fromJson(item))
                  .toList();
            }
          }
        }
        
        // 兼容 JSON 格式
        if (data is Map<String, dynamic>) {
          if (data['msg'] != null && data['msg'] is List) {
            return (data['msg'] as List)
                .map((item) => MessageModel.fromJson(item))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('获取消息列表失败: $e');
      return [];
    }
  }

  /// 发送消息（Protobuf格式）
  static Future<bool> sendMessage({
    required String chatId,
    required int chatType,
    required String msgId,
    required String text,
    int contentType = 1,
    String? quoteMsgId,
    int? commandId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendMessage}');
      
      // 使用 Protobuf 编码请求
      final bodyBytes = encodeSendMessage(
        msgId: msgId,
        chatId: chatId,
        chatType: chatType,
        text: text,
        contentType: contentType,
        quoteMsgId: quoteMsgId,
        commandId: commandId,
      );

      final response = await http.post(
        url,
        headers: _getHeaders(isProtobuf: true),
        body: bodyBytes,
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        // Protobuf 响应，解析状态
        final data = _parseResponse(response);
        
        if (data is Uint8List) {
          // 解析 Protobuf 响应
          final parser = ProtobufParser(data);
          Status? status;
          
          while (parser.hasMore) {
            final tag = parser.readTag();
            if (tag == null) break;
            
            final (fieldNumber, wireType) = tag;
            if (fieldNumber == 1) { // status
              final statusBytes = parser.readLengthDelimited();
              if (statusBytes != null) {
                status = parseStatus(statusBytes);
                break;
              }
            } else {
              parser.skipField(wireType);
            }
          }
          
          return status?.code == 1;
        }
        
        // 兼容 JSON 格式
        if (data is Map<String, dynamic>) {
          return data['code'] == 1;
        }
      }
      return false;
    } catch (e) {
      print('发送消息失败: $e');
      return false;
    }
  }
}

