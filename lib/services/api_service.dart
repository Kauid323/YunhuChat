import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/community_model.dart';
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

  /// 获取图片验证码
  static Future<Map<String, dynamic>?> getCaptcha({
    required String deviceId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userCaptcha}');
      final body = {
        'deviceId': deviceId,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(includeToken: false),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      if (data['code'] == 1 && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('获取验证码失败: $e');
      return null;
    }
  }

  /// 获取短信验证码
  static Future<bool> getVerificationCode({
    required String mobile,
    required String code,
    required String id,
    String platform = 'android',
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getVerificationCode}');
      final body = {
        'mobile': mobile,
        'code': code,
        'id': id,
        'platform': platform,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(includeToken: false),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      return data['code'] == 1;
    } catch (e) {
      print('获取短信验证码失败: $e');
      return false;
    }
  }

  /// 手机号验证码登录
  static Future<LoginResponse> verificationLogin({
    required String mobile,
    required String captcha,
    required String deviceId,
    String platform = 'android',
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userVerificationLogin}');
      final body = {
        'mobile': mobile,
        'captcha': captcha,
        'deviceId': deviceId,
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

  /// 获取用户详情（Protobuf格式）
  static Future<Map<String, dynamic>?> getUserDetail(String userId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getUser}');
      final requestBody = encodeGetUser(userId: userId);
      
      final response = await http.post(
        url,
        headers: _getHeaders(isProtobuf: true),
        body: requestBody,
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        
        // 如果是 Protobuf 格式（字节数组）
        if (data is Uint8List) {
          var parseGetUser2 = parseGetUser(data);
          return parseGetUser2;
        }
      }
      return null;
    } catch (e) {
      print('获取用户详情失败: $e');
      return null;
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
      print('========== 发送消息开始 ==========');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.sendMessage}');
      print('参数: chatId=$chatId, chatType=$chatType, msgId=$msgId, text=$text, contentType=$contentType');
      
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
      
      print('编码后的请求体长度: ${bodyBytes.length} 字节');
      print('请求体前20字节: ${bodyBytes.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      final headers = _getHeaders(isProtobuf: true);
      print('请求头: $headers');

      final response = await http.post(
        url,
        headers: headers,
        body: bodyBytes,
      ).timeout(ApiConfig.connectionTimeout);

      print('响应状态码: ${response.statusCode}');
      print('响应Content-Type: ${response.headers['content-type']}');
      print('响应体长度: ${response.bodyBytes.length} 字节');
      
      if (response.statusCode == 200) {
        // Protobuf 响应，解析状态
        final data = _parseResponse(response);
        
        if (data is Uint8List) {
          print('响应是 Protobuf 格式，开始解析...');
          print('响应体前20字节: ${data.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          
          // 解析 Protobuf 响应
          final parser = ProtobufParser(data);
          Status? status;
          
          while (parser.hasMore) {
            final tag = parser.readTag();
            if (tag == null) break;
            
            final (fieldNumber, wireType) = tag;
            print('解析字段: fieldNumber=$fieldNumber, wireType=$wireType');
            
            if (fieldNumber == 1) { // status
              final statusBytes = parser.readLengthDelimited();
              if (statusBytes != null) {
                print('解析 status，长度: ${statusBytes.length}');
                status = parseStatus(statusBytes);
                print('Status: code=${status?.code}, msg=${status?.msg}');
                break;
              }
            } else {
              parser.skipField(wireType);
            }
          }
          
          final success = status?.code == 1;
          print('发送消息结果: ${success ? "成功" : "失败"}');
          if (!success) {
            print('失败原因: code=${status?.code}, msg=${status?.msg}');
          }
          print('========== 发送消息结束 ==========');
          return success;
        }
        
        // 兼容 JSON 格式
        if (data is Map<String, dynamic>) {
          print('响应是 JSON 格式: $data');
          final success = data['code'] == 1;
          print('发送消息结果: ${success ? "成功" : "失败"}');
          print('========== 发送消息结束 ==========');
          return success;
        }
        
        print('响应格式未知: ${data.runtimeType}');
      } else {
        print('HTTP 错误: statusCode=${response.statusCode}');
        print('响应体: ${response.body}');
      }
      
      print('========== 发送消息结束 ==========');
      return false;
    } catch (e, stackTrace) {
      print('========== 发送消息异常 ==========');
      print('异常类型: ${e.runtimeType}');
      print('异常信息: $e');
      print('堆栈跟踪:');
      print(stackTrace);
      print('========== 发送消息异常结束 ==========');
      return false;
    }
  }


  /// 获取社区文章列表
  static Future<List<CommunityPost>> getCommunityPosts({
    int page = 1,
    int size = 20,
    int baId = 41, // 默认云湖分区
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityPostList}');
      final body = {
        'typ': 1,
        'baId': baId,
        'size': size,
        'page': page,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      if (data['code'] == 1 && data['data'] != null) {
        final posts = data['data']['posts'] as List?;
        if (posts != null) {
          return posts.map((e) => CommunityPost.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('获取文章列表失败: $e');
      return [];
    }
  }

  /// 获取关注的分区列表
  static Future<List<CommunityPartition>> getCommunityPartitions({
    int page = 1,
    int size = 20,
    int type = 2,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityPartitionList}');
      final body = {
        'typ': type,
        'size': size,
        'page': page,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      if (data['code'] == 1 && data['data'] != null) {
        final bas = data['data']['ba'] as List?;
        if (bas != null) {
          return bas.map((e) => CommunityPartition.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('获取分区列表失败: $e');
      return [];
    }
  }

  /// 发布文章
  static Future<bool> createPost({
    required int baId,
    required String title,
    required String content,
    int contentType = 1, // 1-文本，2-markdown
    String groupId = '',
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityPostCreate}');
      final body = {
        'baId': baId,
        'title': title,
        'content': content,
        'contentType': contentType,
        'groupId': groupId,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      return data['code'] == 1;
    } catch (e) {
      print('发布文章失败: $e');
      return false;
    }
  }

  /// 获取文章详情
  static Future<CommunityPostDetailData?> getPostDetail({
    required int postId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityPostDetail}');
      final body = {'id': postId};

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      if (data['code'] == 1 && data['data'] != null) {
        return CommunityPostDetailData.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      print('获取文章详情失败: $e');
      return null;
    }
  }

  /// 发送评论
  static Future<bool> sendComment({
    required int postId,
    required String content,
    int commentId = 0, // 0表示评论文章
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityComment}');
      final body = {
        'postId': postId,
        'commentId': commentId,
        'content': content,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      return data['code'] == 1;
    } catch (e) {
      print('发送评论失败: $e');
      return false;
    }
  }

  /// 点赞/取消点赞
  static Future<bool> likePost({
    required int postId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityPostLike}');
      final body = {'id': postId};

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      return data['code'] == 1;
    } catch (e) {
      print('点赞操作失败: $e');
      return false;
    }
  }

  /// 收藏/取消收藏
  static Future<bool> collectPost({
    required int postId,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityPostCollect}');
      final body = {'id': postId};

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      return data['code'] == 1;
    } catch (e) {
      print('收藏操作失败: $e');
      return false;
    }
  }

  /// 获取评论列表
  static Future<List<CommunityComment>> getComments({
    required int postId,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.communityCommentList}');
      final body = {
        'postId': postId,
        'size': size,
        'page': page,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(ApiConfig.connectionTimeout);

      final data = jsonDecode(response.body);
      if (data['code'] == 1 && data['data'] != null) {
        final comments = data['data']['comments'] as List?;
        if (comments != null) {
          return comments.map((e) => CommunityComment.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('获取评论列表失败: $e');
      return [];
    }
  }
}

