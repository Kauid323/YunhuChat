import 'package:flutter/foundation.dart';
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
    // 保存原有的回调
    final originalCallback = wsService.onMessageReceived;
    
    wsService.onMessageReceived = (data) {
      // 先调用原有回调
      originalCallback?.call(data);
      
      final cmd = data['cmd']?.toString() ?? '';
      
      if (cmd == 'push_message') {
        final msgData = data['data']?['msg'];
        if (msgData != null) {
          // 检查是否是当前聊天的消息
          final msgChatId = msgData['chat_id']?.toString();
          if (msgChatId == chatId) {
            _handleNewMessage(msgData);
          }
        }
      }
    };
  }

  /// 处理新消息
  void _handleNewMessage(Map<String, dynamic> msgData) {
    try {
      final message = MessageModel.fromJson(msgData);
      
      // 检查消息是否已存在
      if (!_messages.any((m) => m.msgId == message.msgId)) {
        _messages.add(message);
        _messages.sort((a, b) {
          final timeA = a.sendTime ?? 0;
          final timeB = b.sendTime ?? 0;
          return timeA.compareTo(timeB);
        });
        notifyListeners();
      }
    } catch (e) {
      print('处理新消息失败: $e');
    }
  }

  /// 加载消息列表
  Future<void> loadMessages({String? fromMsgId}) async {
    if (fromMsgId == null) {
      // 首次加载
      _isLoading = true;
      _hasMoreMessages = true;
      _isInitialLoad = true;
    } else {
      // 加载更多
      if (_isLoadingMore || !_hasMoreMessages) return;
      _isLoadingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final newMessages = await ApiService.getMessageList(
        chatId: chatId,
        chatType: chatType,
        msgCount: 30,
        msgId: fromMsgId,
      );

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
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载消息失败: ${e.toString()}';
      _isLoading = false;
      _isLoadingMore = false;
      _isInitialLoad = false;
      notifyListeners();
    }
  }

  /// 发送消息
  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      // 生成消息ID
      final msgId = DateTime.now().millisecondsSinceEpoch.toString() + 
                   '_${chatId}_${text.hashCode}';

      final success = await ApiService.sendMessage(
        chatId: chatId,
        chatType: chatType,
        msgId: msgId,
        text: text,
      );

      _isSending = false;
      notifyListeners();

      if (success) {
        // 发送成功后重新加载消息列表
        await loadMessages();
        return true;
      } else {
        _errorMessage = '发送消息失败';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '发送消息失败: ${e.toString()}';
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// 加载更多历史消息
  Future<void> loadMoreMessages() async {
    if (_messages.isEmpty || _isLoadingMore || !_hasMoreMessages) return;
    
    final oldestMsg = _messages.first;
    await loadMessages(fromMsgId: oldestMsg.msgId);
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

