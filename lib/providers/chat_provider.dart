import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';

/// 聊天状态管理
class ChatProvider with ChangeNotifier {
  final String chatId;
  final int chatType;
  final WebSocketService wsService;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  bool _isInitialLoad = true; // 标记是否是首次加载
  String? _errorMessage;
  bool _disposed = false; // 标记是否已 dispose
  StreamSubscription? _messageSubscription;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isInitialLoad => _isInitialLoad;
  String? get errorMessage => _errorMessage;

  ChatProvider({
    required this.chatId,
    required this.chatType,
    required this.wsService,
  }) {
    _setupWebSocketListener();
    loadMessages();
  }

  /// 设置WebSocket消息监听
  void _setupWebSocketListener() {
    _messageSubscription = wsService.messageStream.listen((data) {
      final cmd = data['cmd']?.toString() ?? '';

      if (cmd == 'push_message') {
        final msgData = data['data']?['msg'];
        if (msgData != null) {
          final msgChatId = msgData['chat_id']?.toString();
          if (msgChatId == chatId) {
            _handleNewMessage(msgData);
          }
        }
      }
    });
  }

  /// 处理新消息
  void _handleNewMessage(Map<String, dynamic> msgData) {
    if (_disposed) return;
    try {
      final patched = Map<String, dynamic>.from(msgData);
      // WebSocket 推送字段为 timestamp/recv_id，适配成 MessageModel 所需字段
      if (!patched.containsKey('send_time') && patched['timestamp'] != null) {
        patched['send_time'] = patched['timestamp'];
      }
      if (!patched.containsKey('sender')) {
        patched['sender'] = msgData['sender'] ?? <String, dynamic>{};
      }

      // 有些推送会把内容字段放在顶层（text/image_url/...），或者 content 为空
      final dynamic rawContent = patched['content'];
      final Map<String, dynamic> contentMap = rawContent is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawContent)
          : (rawContent is Map ? Map<String, dynamic>.from(rawContent.cast<String, dynamic>()) : <String, dynamic>{});
      if (contentMap.isEmpty) {
        for (final key in <String>[
          'text',
          'image_url',
          'file_name',
          'file_url',
          'file_size',
          'video_url',
          'audio_url',
          'audio_time',
          'quote_msg_text',
        ]) {
          final v = patched[key];
          if (v != null && (v is! String || v.isNotEmpty)) {
            contentMap[key] = v;
          }
        }
        patched['content'] = contentMap;
      } else {
        // content 存在但内部字段缺失时，用顶层字段兜底
        for (final key in <String>[
          'text',
          'image_url',
          'file_name',
          'file_url',
          'file_size',
          'video_url',
          'audio_url',
          'audio_time',
          'quote_msg_text',
        ]) {
          final existing = contentMap[key];
          if ((existing == null || (existing is String && existing.isEmpty)) && patched[key] != null) {
            contentMap[key] = patched[key];
          }
        }
        patched['content'] = contentMap;
      }

      final currentUserId = StorageService.getUserId();
      final senderChatId = (patched['sender'] is Map)
          ? (patched['sender'] as Map)['chat_id']?.toString() ?? (patched['sender'] as Map)['chatId']?.toString()
          : null;
      if (!patched.containsKey('direction') && currentUserId != null && senderChatId != null) {
        patched['direction'] = senderChatId == currentUserId ? 'right' : 'left';
      }

      final message = MessageModel.fromJson(patched);
      
      // 检查消息是否已存在
      if (!_messages.any((m) => m.msgId == message.msgId)) {
        // 新消息直接追加到末尾（不调整已加载消息的顺序）
        _messages.add(message);
        if (!_disposed) notifyListeners();
      }
    } catch (e) {
      print('处理新消息失败: $e');
    }
  }

  /// 加载消息列表
  Future<void> loadMessages({String? fromMsgId}) async {
    if (_disposed) return;
    
    if (fromMsgId == null) {
      // 首次加载
      _isLoading = true;
      _hasMoreMessages = true;
      _isInitialLoad = true;
    } else {
      // 加载更多
      if (_isLoadingMore || !_hasMoreMessages || _disposed) return;
      _isLoadingMore = true;
    }
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    try {
      final newMessages = await ApiService.getMessageList(
        chatId: chatId,
        chatType: chatType,
        msgCount: 30,
        msgId: fromMsgId,
      );

      if (_disposed) return;

      if (fromMsgId == null) {
        // 首次加载，替换所有消息
        _messages = newMessages;
        _hasMoreMessages = newMessages.length >= 30;
        _isInitialLoad = false; // 首次加载完成
      } else {
        // 加载历史消息，插入到前面
        if (newMessages.isEmpty) {
          _hasMoreMessages = false;
        } else {
          // 检查是否有重复消息，避免重复添加
          final existingMsgIds = _messages.map((m) => m.msgId).toSet();
          final uniqueNewMessages = newMessages.where((m) => !existingMsgIds.contains(m.msgId)).toList();
          
          if (uniqueNewMessages.isNotEmpty) {
            _messages.insertAll(0, uniqueNewMessages);
          }
          
          // 如果返回的消息数量少于请求数量，说明没有更多消息了
          if (newMessages.length < 30) {
            _hasMoreMessages = false;
          }
        }
      }

      // 按时间排序（从旧到新）
      _messages.sort((a, b) {
        final timeA = a.sendTime ?? 0;
        final timeB = b.sendTime ?? 0;
        return timeA.compareTo(timeB);
      });

      _isLoading = false;
      _isLoadingMore = false;
      if (!_disposed) notifyListeners();
    } catch (e) {
      if (_disposed) return;
      _errorMessage = '加载消息失败: ${e.toString()}';
      _isLoading = false;
      _isLoadingMore = false;
      _isInitialLoad = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// 发送消息
  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty || _disposed) return false;

    _isSending = true;
    if (!_disposed) notifyListeners();

    try {
      // 生成消息ID (使用 UUID，类似 Python 的 uuid.uuid4().hex)
      final msgId = const Uuid().v4().replaceAll('-', '');

      final success = await ApiService.sendMessage(
        chatId: chatId,
        chatType: chatType,
        msgId: msgId,
        text: text,
      );

      if (_disposed) return false;

      _isSending = false;
      if (!_disposed) notifyListeners();

      if (success) {
        // 发送成功后重新加载消息列表
        await loadMessages();
        return true;
      } else {
        _errorMessage = '发送消息失败';
        if (!_disposed) notifyListeners();
        return false;
      }
    } catch (e) {
      if (_disposed) return false;
      _errorMessage = '发送消息失败: ${e.toString()}';
      _isSending = false;
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  /// 加载更多历史消息
  Future<void> loadMoreMessages() async {
    if (_messages.isEmpty || _isLoadingMore || !_hasMoreMessages) return;
    
    // 列表为旧 -> 新，最旧消息在开头
    final oldestMsg = _messages.first;
    await loadMessages(fromMsgId: oldestMsg.msgId);
  }

  /// 清除错误信息
  void clearError() {
    if (_disposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _messageSubscription?.cancel();
    super.dispose();
  }
}

