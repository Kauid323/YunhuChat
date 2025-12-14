import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yunhum3/services/websocket_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../utils/image_loader.dart';
import 'chat_screen.dart';
import '../services/storage_service.dart';

/// 会话列表页面
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  StreamSubscription? _messageSubscription;
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  bool _isSearching = false;
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearchLoading = false;

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
    _searchController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
    });

    try {
      final results = await ApiService.homeSearch(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
        });
      }
    }
  }

  void _updateConversation(Map<String, dynamic> message) {
    final msg = message['data']?['msg'];
    if (msg == null) return;

    final chatId = msg['chat_id']?.toString();
    if (chatId == null) return;

    setState(() {
      final index = _conversations.indexWhere((c) => c.chatId == chatId);
      if (index != -1) {
        final conversation = _conversations.removeAt(index);
        
        // 解析消息内容
        String contentText = '';
        final content = msg['content'];
        if (content != null && content is Map) {
          contentText = content['text']?.toString() ?? '';
          // 如果文本为空，尝试其他类型
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
          timestampMs: msg['timestamp'] is int ? msg['timestamp'] : int.tryParse(msg['timestamp']?.toString() ?? ''),
          unreadMessage: (conversation.unreadMessage ?? 0) + 1, // 收到新消息增加未读数
        );
        _conversations.insert(0, updatedConversation);
      }
    });
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

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await ApiService.getConversationList();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索...',
                  border: InputBorder.none,
                ),
                onSubmitted: _performSearch,
              )
            : const Text('云湖'),
        actions: _isSearching
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _searchResults.clear();
                    });
                  },
                ),
              ]
            : StorageService.getConversationAppBarActions().map((action) {
                switch (action) {
                  case 'search':
                    return IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    );
                  default:
                    return const SizedBox.shrink();
                }
              }).toList(),
      ),
      body: _isSearching
          ? _buildSearchResults()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无会话',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundImage: conversation.avatarUrl != null
                                  ? ImageLoader.networkImageProvider(conversation.avatarUrl!)
                                  : null,
                              child: conversation.avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            if (conversation.hasUnread)
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(conversation.name),
                        subtitle: Text(
                          conversation.chatContent ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatTime(conversation.timestampMs),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        onTap: () async {
                          // 标记为已读
                          await ApiService.markConversationAsRead(
                            chatId: conversation.chatId,
                            chatType: conversation.chatType,
                          );
                          
                          // 更新本地状态
                          setState(() {
                            // 重新创建 ConversationModel 对象来更新未读消息
                            final index = _conversations.indexWhere((c) => c.chatId == conversation.chatId);
                            if (index != -1) {
                              _conversations[index] = ConversationModel(
                                chatId: conversation.chatId,
                                chatType: conversation.chatType,
                                name: conversation.name,
                                chatContent: conversation.chatContent,
                                timestampMs: conversation.timestampMs,
                                unreadMessage: 0, // 标记为已读
                                at: conversation.at,
                                avatarId: conversation.avatarId,
                                avatarUrl: conversation.avatarUrl,
                                doNotDisturb: conversation.doNotDisturb,
                                timestamp: conversation.timestamp,
                                certificationLevel: conversation.certificationLevel,
                              );
                            }
                          });
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: conversation.chatId,
                                chatType: conversation.chatType,
                                chatName: conversation.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text('没有搜索结果'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final category = _searchResults[index];
        final title = category['title'];
        final items = category['list'] as List<dynamic>?;

        if (items == null || items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...items.map((item) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: item['avatarUrl'] != null
                      ? ImageLoader.networkImageProvider(item['avatarUrl']!)
                      : null,
                  child: item['avatarUrl'] == null ? const Icon(Icons.group) : null,
                ),
                title: Text(item['nickname'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: item['friendId'].toString(),
                        chatType: item['friendType'],
                        chatName: item['nickname'] ?? '',
                      ),
                    ),
);
                },
              );
            }),
          ],
        );
      },
    );
  }
}

