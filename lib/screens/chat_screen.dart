import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../models/message_model.dart';
import '../utils/image_loader.dart';
import 'user_detail_screen.dart';
import 'group_info_screen.dart';
import 'package:intl/intl.dart';
import '../utils/latex_config.dart';

/// 聊天页面
class ChatScreen extends StatefulWidget {
  final String chatId;
  final int chatType;
  final String chatName;
  final bool showAppBar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatType,
    required this.chatName,
    this.showAppBar = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

void _showVideoPlayerDialog(BuildContext context, String videoUrl) {
  debugPrint('[video10] open dialog url=$videoUrl');
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (context) {
      debugPrint('[video10] build HtmlWidget video url=$videoUrl');
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: HtmlWidget(
                    '<video controls autoplay src="$videoUrl"></video>',
                    factoryBuilder: () => _ChatHtmlWidgetFactory(),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showImagePreviewDialog(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    barrierColor: Colors.black,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: ImageLoader.networkImage(
                    url: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
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
        chatId: widget.chatId,
        chatType: widget.chatType,
        chatName: widget.chatName,
        textController: _textController,
        scrollController: _scrollController,
        focusNode: _focusNode,
        showAppBar: widget.showAppBar,
      ),
    );
  }
}

class _ChatHtmlWidgetFactory extends WidgetFactory {}

class _AnimatedInsertedMessage extends StatefulWidget {
  final bool play;
  final VoidCallback? onAnimationEnd;
  final Widget child;

  const _AnimatedInsertedMessage({
    super.key,
    required this.play,
    required this.child,
    this.onAnimationEnd,
  });

  @override
  State<_AnimatedInsertedMessage> createState() => _AnimatedInsertedMessageState();
}

class _AnimatedInsertedMessageState extends State<_AnimatedInsertedMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _AnimatedInsertedMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !_played) {
      _played = true;
      _controller.forward().whenComplete(() {
        widget.onAnimationEnd?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.play && !_played) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

/// 聊天内容（分离出来以便访问Provider）
class _ChatContent extends StatefulWidget {
  final String chatId;
  final int chatType;
  final String chatName;
  final TextEditingController textController;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final bool showAppBar;

  const _ChatContent({
    required this.chatId,
    required this.chatType,
    required this.chatName,
    required this.textController,
    required this.scrollController,
    required this.focusNode,
    required this.showAppBar,
  });

  @override
  State<_ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<_ChatContent> {
  bool _hasInitializedScroll = false; // 标记是否已经初始化滚动
  final Set<String> _knownMsgIds = <String>{};
  final Set<String> _newlyInsertedMsgIds = <String>{};
  ChatProvider? _chatProvider;
  bool _hasSeededKnownIds = false;

  void _openGroupInfo() {
    final isWindows = !kIsWeb && Platform.isWindows;
    if (!isWindows) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GroupInfoScreen(
            groupId: widget.chatId,
          ),
        ),
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'GroupInfo',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        final width = MediaQuery.of(context).size.width;
        final sheetWidth = width >= 1200 ? 520.0 : (width * 0.42).clamp(360.0, 520.0);
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 16,
            child: SizedBox(
              width: sheetWidth,
              height: double.infinity,
              child: GroupInfoScreen(
                groupId: widget.chatId,
                showAppBar: false,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // 监听输入框焦点变化
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ChatProvider>(context);
    if (!identical(_chatProvider, provider)) {
      _chatProvider?.removeListener(_onChatProviderChanged);
      _chatProvider = provider;
      _chatProvider?.addListener(_onChatProviderChanged);
      _onChatProviderChanged();
    }
  }

  void _onChatProviderChanged() {
    if (!mounted) return;
    final provider = _chatProvider;
    if (provider == null) return;

    final currentMsgIds = provider.messages
        .map((m) => m.msgId)
        .whereType<String>()
        .toSet();

    // 首次建立已知集合：不播放动画
    if (!_hasSeededKnownIds) {
      _hasSeededKnownIds = true;
      _knownMsgIds
        ..clear()
        ..addAll(currentMsgIds);
      _newlyInsertedMsgIds.clear();
      return;
    }

    // 加载更多 / 首次加载 / 全量刷新时，避免整屏动画和状态抖动
    if (provider.isLoadingMore || provider.isInitialLoad) {
      _knownMsgIds
        ..clear()
        ..addAll(currentMsgIds);
      _newlyInsertedMsgIds.clear();
      return;
    }

    final newMsgIds = currentMsgIds.difference(_knownMsgIds);
    if (newMsgIds.isEmpty) {
      // 处理删除/撤回等情况：同步 known 集合
      if (currentMsgIds.length != _knownMsgIds.length) {
        _knownMsgIds
          ..clear()
          ..addAll(currentMsgIds);
      }
      return;
    }

    // 如果一次性新增太多（例如 sendMessage 后触发 loadMessages 全量替换），只播最后一条
    final idsToAnimate = newMsgIds.length > 3
        ? <String>{newMsgIds.last}
        : newMsgIds;

    setState(() {
      _newlyInsertedMsgIds.addAll(idsToAnimate);
      _knownMsgIds.addAll(newMsgIds);
    });
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _chatProvider?.removeListener(_onChatProviderChanged);
    super.dispose();
  }

  void _onFocusChange() {
    // 当输入框获得焦点时，延迟滚动到底部，等待键盘弹出
    if (widget.focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || !widget.focusNode.hasFocus) return;
        if (!widget.scrollController.hasClients) return;
        final position = widget.scrollController.position;
        final distanceToBottom = position.maxScrollExtent - position.pixels;
        // 只有当用户本来就在接近底部（正在看最新消息）时，才自动滚回最新
        if (distanceToBottom < 120) {
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
        appBar: widget.showAppBar
            ? AppBar(
                title: Text(widget.chatName),
                actions: [
                  if (widget.chatType == 1)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserDetailScreen(
                              userId: widget.chatId,
                            ),
                          ),
                        );
                      },
                    ),
                  if (widget.chatType == 2)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _openGroupInfo();
                      },
                    ),
                ],
              )
            : null,
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
                        final msgId = message.msgId;
                        final shouldAnimate = msgId != null && _newlyInsertedMsgIds.contains(msgId);
                        return _AnimatedInsertedMessage(
                          key: msgId != null ? ValueKey<String>(msgId) : null,
                          play: shouldAnimate,
                          onAnimationEnd: () {
                            if (!mounted) return;
                            if (msgId == null) return;
                            setState(() {
                              _newlyInsertedMsgIds.remove(msgId);
                            });
                          },
                          child: _MessageBubble(message: message),
                        );
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
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, MessageModel message) {
    // 优先处理 Markdown，防止 switch case 匹配问题
    if (message.contentType == 3) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final baseConfig = isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;

      Widget codeBlockWrapper(Widget child, String code, String language) {
        return Builder(
          builder: (context) {
            final label = language.trim();
            return Stack(
              children: [
                child,
                Positioned(
                  top: 6,
                  right: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (label.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          tooltip: '复制',
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: code));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }
      final codeConfig = isDark
          ? PreConfig.darkConfig.copy(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              wrapper: codeBlockWrapper,
            )
          : const PreConfig().copy(
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              wrapper: codeBlockWrapper,
            );

      return MarkdownWidget(
        data: message.content.text ?? '',
        config: baseConfig.copy(
          configs: [
            codeConfig,
          ],
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        markdownGenerator: MarkdownGenerator(
          inlineSyntaxList: [LatexSyntax()],
          generators: [latexGenerator],
        ),
      );
    }

    if (message.contentType == 8) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final effectiveTextColor = message.isMyMessage
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface;
      String cssColor(Color color) {
        final rgb = color.value & 0x00FFFFFF;
        return '#${rgb.toRadixString(16).padLeft(6, '0')}';
      }

      final rawHtml = message.content.text ?? '';
      final safeHtml = rawHtml.replaceAll(
        RegExp(r'display\s*:\s*flex', caseSensitive: false),
        'display: block',
      );

      bool needReferer(String url) {
        try {
          final uri = Uri.parse(url);
          final host = uri.host;
          if (host.isEmpty) return false;
          return host == 'jwznb.com' || host.endsWith('.jwznb.com');
        } catch (_) {
          return false;
        }
      }

      return HtmlWidget(
        safeHtml,
        factoryBuilder: () => _ChatHtmlWidgetFactory(),
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: message.isMyMessage
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
        onTapUrl: (url) async {
          await Clipboard.setData(ClipboardData(text: url));
          if (!context.mounted) return true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('链接已复制')),
          );
          return true;
        },
        customWidgetBuilder: (element) {
          // Let flutter_widget_from_html render everything by default.
          // Only hijack jwznb.com images to inject Referer headers via ImageLoader.
          if (element.localName == 'img') {
            final src = element.attributes['src'];
            if (src == null || src.isEmpty) return null;
            if (!needReferer(src)) return null;

            return GestureDetector(
              onTap: () {
                _showImagePreviewDialog(context, src);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ImageLoader.networkImage(
                  url: src,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }

          if (element.localName == 'table') {
            // The default table renderer may overflow horizontally.
            // Wrap it in a horizontal scroll view and let HtmlWidget do the real rendering.
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 320),
                child: HtmlWidget(
                  element.outerHtml,
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: message.isMyMessage
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                  onTapUrl: (url) async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (!context.mounted) return true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('链接已复制')),
                    );
                    return true;
                  },
                  customWidgetBuilder: (e) {
                    // Avoid infinite recursion.
                    if (e.localName == 'table') return null;
                    if (e.localName == 'img') {
                      final src = e.attributes['src'];
                      if (src == null || src.isEmpty) return null;
                      if (!needReferer(src)) return null;
                      return GestureDetector(
                        onTap: () {
                          _showImagePreviewDialog(context, src);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ImageLoader.networkImage(
                            url: src,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  customStylesBuilder: (e) {
                    if (!isDark) return null;
                    final style = e.attributes['style'];
                    if (style == null || style.isEmpty) return null;
                    final normalized = style.toLowerCase().replaceAll(' ', '');
                    final hasBadBlack = normalized.contains('color:#000000') ||
                        normalized.contains('color:rgb(0,0,0)');
                    final hasNone = normalized.contains('color:none');
                    if (!hasBadBlack && !hasNone) return null;
                    return <String, String>{'color': cssColor(effectiveTextColor)};
                  },
                ),
              ),
            );
          }
          return null;
        },
        customStylesBuilder: (element) {
          if (!isDark) return null;
          final style = element.attributes['style'];
          if (style == null || style.isEmpty) return null;
          final normalized = style.toLowerCase().replaceAll(' ', '');
          final hasBadBlack =
              normalized.contains('color:#000000') || normalized.contains('color:rgb(0,0,0)');
          final hasNone = normalized.contains('color:none');
          if (!hasBadBlack && !hasNone) return null;
          return <String, String>{'color': cssColor(effectiveTextColor)};
        },
      );
    }

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
            ? GestureDetector(
                onTap: () {
                  _showImagePreviewDialog(context, message.content.imageUrl!);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ImageLoader.networkImage(
                    url: message.content.imageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
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
      case 10: // 视频
        final url = message.content.videoUrl;
        if (url == null || url.isEmpty) {
          return const Text('[视频]');
        }
        final theme = Theme.of(context);
        return GestureDetector(
          onTap: () {
            final uri = Uri.tryParse(url);
            final isAbsolute = uri != null && uri.hasScheme;
            if (!isAbsolute) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('视频地址无效')),
              );
              return;
            }
            _showVideoPlayerDialog(context, url);
          },
          child: Container(
            width: 220,
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 44,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),
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
