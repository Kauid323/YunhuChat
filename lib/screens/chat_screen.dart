import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/message_model.dart';
import '../utils/image_loader.dart';
import 'user_detail_screen.dart';
import 'package:intl/intl.dart';

/// 聊天页面
class ChatScreen extends StatefulWidget {
  final String chatId;
  final int chatType;
  final String chatName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatType,
    required this.chatName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return ChatProvider(
          chatId: widget.chatId,
          chatType: widget.chatType,
          wsService: authProvider.wsService,
        );
      },
      child: _ChatContent(
        chatName: widget.chatName,
        textController: _textController,
        scrollController: _scrollController,
        focusNode: _focusNode,
      ),
    );
  }
}

/// 聊天内容（分离出来以便访问Provider）
class _ChatContent extends StatefulWidget {
  final String chatName;
  final TextEditingController textController;
  final ScrollController scrollController;
  final FocusNode focusNode;

  const _ChatContent({
    required this.chatName,
    required this.textController,
    required this.scrollController,
    required this.focusNode,
  });

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  bool _hasInitializedScroll = false; // 标记是否已经初始化滚动

  @override
  void initState() {
    super.initState();
    // 监听输入框焦点变化
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    // 当输入框获得焦点时，延迟滚动到底部，等待键盘弹出
    if (widget.focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && widget.focusNode.hasFocus) {
          _scrollToBottom();
        }
      });
    }
  }

  void _scrollToBottom() {
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend(BuildContext context) async {
    final text = widget.textController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.sendMessage(text);

    if (success) {
      widget.textController.clear();
      _scrollToBottom();
    } else if (chatProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
        resizeToAvoidBottomInset: true, // 确保键盘弹出时调整布局
        appBar: AppBar(
          title: Text(widget.chatName),
        ),
        body: Column(
          children: [
            // 消息列表
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (chatProvider.messages.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无消息',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  // 仅在首次加载完成时滚动到底部
                  if (chatProvider.messages.isNotEmpty && 
                      !chatProvider.isLoading && 
                      !chatProvider.isInitialLoad &&
                      !_hasInitializedScroll) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (widget.scrollController.hasClients && mounted) {
                        widget.scrollController.jumpTo(
                          widget.scrollController.position.maxScrollExtent,
                        );
                        setState(() {
                          _hasInitializedScroll = true;
                        });
                      }
                    });
                  }

                  // 当键盘弹出时，自动滚动到底部
                  if (keyboardHeight > 0 && widget.focusNode.hasFocus) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (widget.scrollController.hasClients && mounted) {
                        _scrollToBottom();
                      }
                    });
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // 当滚动到顶部时触发加载更多
                      if (notification is ScrollUpdateNotification) {
                        final position = widget.scrollController.position;
                        // 当滚动到顶部附近时（距离顶部小于200像素），加载更多消息
                        if (position.pixels < 200 &&
                            position.pixels > 0 &&
                            chatProvider.hasMoreMessages &&
                            !chatProvider.isLoadingMore &&
                            !chatProvider.isLoading) {
                          chatProvider.loadMoreMessages();
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: widget.scrollController,
                      reverse: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      itemCount: chatProvider.messages.length + (chatProvider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // 显示加载指示器
                        if (chatProvider.isLoadingMore && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        // 调整索引（如果有加载指示器）
                        final messageIndex = chatProvider.isLoadingMore ? index - 1 : index;
                        if (messageIndex < 0 || messageIndex >= chatProvider.messages.length) {
                          return const SizedBox.shrink();
                        }
                        final message = chatProvider.messages[messageIndex];
                        return _MessageBubble(message: message);
                      },
                    ),
                  );
                },
              ),
            ),
            
                    // 输入框
                    _MessageInput(
                      controller: widget.textController,
                      focusNode: widget.focusNode,
                      onSend: () => _handleSend(context),
                    ),
          ],
        ),
    );
  }
}

/// 消息气泡
class _MessageBubble extends StatelessWidget {
  final MessageModel message;

  const _MessageBubble({required this.message});

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyMessage = message.isMyMessage;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            // 对方头像（可点击）
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserDetailScreen(
                      userId: message.sender.chatId,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: message.sender.avatarUrl != null
                    ? ImageLoader.networkImageProvider(message.sender.avatarUrl!)
                    : null,
                child: message.sender.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.sender.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                // 消息气泡
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 引用消息
                      if (message.content.quoteMsgText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message.content.quoteMsgText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      // 消息内容
                      _buildMessageContent(context, message),
                    ],
                  ),
                ),

                // 时间
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.sendTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isMyMessage) ...[
            const SizedBox(width: 8),
            // 我的头像
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, MessageModel message) {
    switch (message.contentType) {
      case 1: // 文本
        return Text(
          message.content.text ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: message.isMyMessage
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
        );
      case 2: // 图片
        return message.content.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageLoader.networkImage(
                  url: message.content.imageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            : const Text('[图片]');
      case 4: // 文件
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 20,
              color: message.isMyMessage
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content.fileName ?? '[文件]',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: message.isMyMessage
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 11: // 语音
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              size: 20,
              color: message.isMyMessage
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              '${message.content.audioTime ?? 0}秒',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: message.isMyMessage
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        );
      default:
        return Text(
          '[${message.contentTypeText}]',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: message.isMyMessage
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
        );
    }
  }
}

/// 消息输入框
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return IconButton(
                  onPressed: chatProvider.isSending ? null : onSend,
                  icon: chatProvider.isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(12),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
