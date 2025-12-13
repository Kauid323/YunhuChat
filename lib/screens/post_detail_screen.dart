import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/api_service.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../utils/image_loader.dart';
import '../utils/latex_config.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final CommunityPost? previewPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.previewPost,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  CommunityPostDetailData? _detailData;
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

  // Local state for interactions
  bool _isLiked = false;
  bool _isCollected = false;
  int _likeNum = 0;
  int _collectNum = 0;

  final List<CommunityComment> _comments = [];
  bool _isLoadingComments = false;
  int _commentPage = 1;
  bool _hasMoreComments = true; // Simple hasMore flag


  @override
  void initState() {
    super.initState();
    // Initialize with preview data if available
    if (widget.previewPost != null) {
      _isLiked = widget.previewPost!.isLiked;
      _isCollected = widget.previewPost!.isCollected;
      _likeNum = widget.previewPost!.likeNum;
      _collectNum = widget.previewPost!.collectNum;
    }
    _loadDetail();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final data = await ApiService.getPostDetail(postId: widget.postId);
    if (mounted) {
      setState(() {
        _detailData = data;
        _isLoading = false;
        if (data != null) {
          _isLiked = data.post.isLiked;
          _isCollected = data.post.isCollected;
          _likeNum = data.post.likeNum;
          _collectNum = data.post.collectNum;
        }
      });
    }
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (_isLoadingComments) return;
    if (refresh) {
      _commentPage = 1;
      _hasMoreComments = true;
    }
    if (!_hasMoreComments) return;

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await ApiService.getComments(
        postId: widget.postId,
        page: _commentPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) _comments.clear();
          
          if (comments.isEmpty) {
            _hasMoreComments = false;
          } else {
            _comments.addAll(comments);
            _commentPage++;
          }
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likeNum += _isLiked ? 1 : -1;
    });

    final success = await ApiService.likePost(postId: widget.postId);
    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _isLiked = !_isLiked;
        _likeNum += _isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败')),
      );
    }
  }

  Future<void> _toggleCollect() async {
    // Optimistic update
    setState(() {
      _isCollected = !_isCollected;
      _collectNum += _isCollected ? 1 : -1;
    });

    final success = await ApiService.collectPost(postId: widget.postId);
    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _isCollected = !_isCollected;
        _collectNum += _isCollected ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败')),
      );
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSendingComment = true;
    });

    final success = await ApiService.sendComment(
      postId: widget.postId,
      content: content,
    );

    if (mounted) {
      setState(() {
        _isSendingComment = false;
      });
      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论发送成功')),
        );
        _loadComments(refresh: true); // Reload comments
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论发送失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _detailData == null && widget.previewPost == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Use detail data if available, otherwise preview data
    final post = _detailData?.post ?? widget.previewPost;
    final ba = _detailData?.ba;

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('文章详情')),
        body: const Center(child: Text('加载失败')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
             if (ba != null) ...[
               CircleAvatar(
                 radius: 12,
                 backgroundImage: ba.avatar.isNotEmpty
                     ? ImageLoader.networkImageProvider(ba.avatar)
                     : null,
                 child: ba.avatar.isEmpty ? const Icon(Icons.group, size: 12) : null,
               ),
               const SizedBox(width: 8),
               Text(ba.name, style: const TextStyle(fontSize: 16)),
             ] else
               const Text('文章详情'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                    !_isLoadingComments &&
                    _hasMoreComments) {
                  _loadComments();
                }
                return false;
              },
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Author info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.senderAvatar.isNotEmpty
                            ? ImageLoader.networkImageProvider(post.senderAvatar)
                            : null,
                         child: post.senderAvatar.isEmpty 
                            ? const Icon(Icons.person) 
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.senderNickname,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            post.createTimeText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Content
                  if (post.contentType == 2) // Markdown
                    MarkdownWidget(
                      data: post.content,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      markdownGenerator: MarkdownGenerator(
                        inlineSyntaxList: [LatexSyntax()],
                        generators: [latexGenerator],
                      ),
                    )
                  else
                    SelectableText(
                      post.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                    ),
                  
                  const SizedBox(height: 48),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Comments Section
                  Text(
                    '评论 (${_comments.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length + 1,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == _comments.length) {
                        return _hasMoreComments
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: Text('没有更多评论了')),
                              );
                      }
                      
                      final comment = _comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: comment.senderAvatar.isNotEmpty
                                  ? ImageLoader.networkImageProvider(comment.senderAvatar)
                                  : null,
                              child: comment.senderAvatar.isEmpty 
                                  ? const Icon(Icons.person, size: 16) 
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment.senderNickname,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        comment.createTimeText,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.content,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ),
          ),
          
          // Bottom Interaction Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: '说点什么...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        // On submit? Or use a send button?
                        // Let's add a send button if text is not empty, or handled by suffix icon?
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSendingComment 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Icons.send),
                    onPressed: _isSendingComment ? null : _sendComment,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  
                  // Like
                  InkWell(
                    onTap: _toggleLike,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: _isLiked ? Colors.red : null,
                        ),
                        Text(
                          _likeNum > 0 ? '$_likeNum' : '点赞',
                          style: TextStyle(
                            fontSize: 10,
                            color: _isLiked ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Collect
                  InkWell(
                    onTap: _toggleCollect,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCollected ? Icons.star : Icons.star_outline,
                          color: _isCollected ? Colors.orange : null,
                        ),
                        Text(
                          _collectNum > 0 ? '$_collectNum' : '收藏',
                          style: TextStyle(
                            fontSize: 10,
                            color: _isCollected ? Colors.orange : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
