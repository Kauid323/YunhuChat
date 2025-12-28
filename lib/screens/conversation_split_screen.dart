import 'package:flutter/material.dart';
import 'dart:async';

import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../utils/image_loader.dart';
import 'chat_screen.dart';

class ConversationSplitScreen extends StatefulWidget {
  const ConversationSplitScreen({super.key});

  @override
  State<ConversationSplitScreen> createState() => _ConversationSplitScreenState();
}

class _ConversationSplitScreenState extends State<ConversationSplitScreen> {
  StreamSubscription? _messageSubscription;
  bool _isLoading = true;
  List<ConversationModel> _conversations = <ConversationModel>[];
  ConversationModel? _selected;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _messageSubscription = WebSocketService().messageStream.listen((message) {
      if (message['cmd'] == 'push_message') {
        _updateConversation(message);
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _updateConversation(Map<String, dynamic> message) {
    final msg = message['data']?['msg'];
    if (msg == null || msg is! Map) return;

    final chatId = msg['chat_id']?.toString() ?? msg['chatId']?.toString();
    if (chatId == null || chatId.isEmpty) return;

    setState(() {
      final index = _conversations.indexWhere((c) => c.chatId == chatId);
      if (index == -1) return;
      final conversation = _conversations.removeAt(index);

      String contentText = '';
      final content = msg['content'];
      if (content != null && content is Map) {
        contentText = content['text']?.toString() ?? '';
        if (contentText.isEmpty) {
          if (content['image_url'] != null && content['image_url'].toString().isNotEmpty) {
            contentText = '[图片]';
          } else if (content['video_url'] != null && content['video_url'].toString().isNotEmpty) {
            contentText = '[视频]';
          } else if (content['file_url'] != null && content['file_url'].toString().isNotEmpty) {
            contentText = '[文件]';
          }
        }
      }

      final updatedConversation = conversation.copyWith(
        chatContent: contentText,
        timestampMs: msg['timestamp'] is int
            ? msg['timestamp']
            : int.tryParse(msg['timestamp']?.toString() ?? ''),
        unreadMessage: (_selected?.chatId == conversation.chatId)
            ? 0
            : (conversation.unreadMessage ?? 0) + 1,
      );

      _conversations.insert(0, updatedConversation);

      if (_selected?.chatId == conversation.chatId) {
        // 选中会话处于打开状态时：同步本地未读为 0，并通知服务端已读
        // ignore: unawaited_futures
        ApiService.markConversationAsRead(
          chatId: conversation.chatId,
          chatType: conversation.chatType,
        );

        final avatarCache = StorageService.getConversationAvatarUrlCache();
        final cachedUrl = avatarCache[updatedConversation.chatId];
        _selected = updatedConversation.avatarUrl != null && updatedConversation.avatarUrl!.isNotEmpty
            ? updatedConversation
            : (cachedUrl != null && cachedUrl.isNotEmpty
                ? updatedConversation.copyWith(avatarUrl: cachedUrl)
                : updatedConversation);
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    final avatarCache = StorageService.getConversationAvatarUrlCache();

    try {
      final conversations = await ApiService.getConversationList();
      if (!mounted) return;

      final cacheToSave = <String, String>{};
      final patched = conversations.map((c) {
        final cachedUrl = avatarCache[c.chatId];
        final url = c.avatarUrl;
        if (url != null && url.isNotEmpty) {
          cacheToSave[c.chatId] = url;
          return c;
        }
        if (cachedUrl != null && cachedUrl.isNotEmpty) {
          return c.copyWith(avatarUrl: cachedUrl);
        }
        return c;
      }).toList();

      if (cacheToSave.isNotEmpty) {
        // ignore: unawaited_futures
        StorageService.mergeConversationAvatarUrlCache(cacheToSave);
      }

      setState(() {
        _conversations = patched;
        _selected = _selected == null
            ? (patched.isNotEmpty ? patched.first : null)
            : patched.firstWhere(
                (c) => c.chatId == _selected!.chatId,
                orElse: () => patched.isNotEmpty ? patched.first : _selected!,
              );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.year == now.year) {
      return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectConversation(ConversationModel conversation) async {
    setState(() {
      _selected = conversation;
    });

    await ApiService.markConversationAsRead(
      chatId: conversation.chatId,
      chatType: conversation.chatType,
    );

    if (!mounted) return;
    setState(() {
      final index = _conversations.indexWhere((c) => c.chatId == conversation.chatId);
      if (index != -1) {
        _conversations[index] = ConversationModel(
          chatId: conversation.chatId,
          chatType: conversation.chatType,
          name: conversation.name,
          chatContent: conversation.chatContent,
          timestampMs: conversation.timestampMs,
          unreadMessage: 0,
          at: conversation.at,
          avatarId: conversation.avatarId,
          avatarUrl: conversation.avatarUrl,
          doNotDisturb: conversation.doNotDisturb,
          timestamp: conversation.timestamp,
          certificationLevel: conversation.certificationLevel,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leftWidth = 360.0;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: leftWidth,
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Text('云湖', style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        IconButton(
                          onPressed: _loadConversations,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _conversations.isEmpty
                          ? Center(
                              child: Text(
                                '暂无会话',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                final c = _conversations[index];
                                final isSelected = _selected?.chatId == c.chatId;

                                return Material(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    selected: isSelected,
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      backgroundImage: c.avatarUrl != null
                                          ? ImageLoader.networkImageProvider(c.avatarUrl!)
                                          : null,
                                      child: c.avatarUrl == null
                                          ? Icon(
                                              Icons.person,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      c.chatContent ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      _formatTime(c.timestampMs),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    onTap: () => _selectConversation(c),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selected == null
                ? Center(
                    child: Text(
                      '请选择一个会话',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ChatScreen(
                    key: ValueKey<String>(_selected!.chatId),
                    chatId: _selected!.chatId,
                    chatType: _selected!.chatType,
                    chatName: _selected!.name,
                    showAppBar: true,
                  ),
          ),
        ],
      ),
    );
  }
}
