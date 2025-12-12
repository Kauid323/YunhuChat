import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/api_service.dart';
import '../utils/image_loader.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<CommunityPost> _posts = [];
  bool _isLoading = false;
  int _page = 1;
  int _baId = 41; // 默认云湖分区
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _page = 1;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await ApiService.getCommunityPosts(
        page: _page,
        baId: _baId,
      );

      setState(() {
        if (refresh) {
          _posts.clear();
        }
        _posts.addAll(posts);
        if (posts.isNotEmpty) {
          _page++;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社区'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showPartitionFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePostScreen(baId: _baId),
            ),
          );
          if (result == true) {
            _loadPosts(refresh: true);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPosts(refresh: true),
        child: _posts.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无文章',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                itemCount: _posts.length + 1,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    return _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }

                  final post = _posts[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            postId: post.id,
                            previewPost: post,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                backgroundImage: post.senderAvatar.isNotEmpty
                                    ? ImageLoader.networkImageProvider(post.senderAvatar)
                                    : null,
                                child: post.senderAvatar.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (post.content.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              post.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildActionIcon(
                                context,
                                Icons.thumb_up_outlined,
                                post.likeNum.toString(),
                              ),
                              const SizedBox(width: 24),
                              _buildActionIcon(
                                context,
                                Icons.chat_bubble_outline,
                                post.commentNum.toString(),
                              ),
                              const SizedBox(width: 24),
                              _buildActionIcon(
                                context,
                                Icons.star_outline,
                                post.collectNum.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showPartitionFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_fire_department_outlined, color: Colors.orange),
                title: const Text('热门分区'),
                onTap: () {
                  Navigator.pop(context);
                  _showPartitionListSheet(2); // Typ 2
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view_outlined, color: Colors.blue),
                title: const Text('全部分区'),
                onTap: () {
                  Navigator.pop(context);
                  _showPartitionListSheet(4); // Typ 4
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border, color: Colors.red),
                title: const Text('已关注的分区'),
                onTap: () {
                  Navigator.pop(context);
                  _showPartitionListSheet(1); // Typ 1
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.green),
                title: const Text('我的'),
                onTap: () {
                  Navigator.pop(context);
                  _showPartitionListSheet(3); // Typ 3
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPartitionListSheet(int type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _PartitionListSheet(
          type: type,
          onPartitionSelected: (partition) {
            setState(() {
              _baId = partition.id;
            });
            Navigator.pop(context);
            _loadPosts(refresh: true);
          },
        );
      },
    );
  }
}

class _PartitionListSheet extends StatefulWidget {
  final int type;
  final Function(CommunityPartition) onPartitionSelected;

  const _PartitionListSheet({
    required this.type,
    required this.onPartitionSelected,
  });

  @override
  State<_PartitionListSheet> createState() => _PartitionListSheetState();
}

class _PartitionListSheetState extends State<_PartitionListSheet> {
  final List<CommunityPartition> _partitions = [];
  bool _isLoading = false;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPartitions();
    _scrollController.addListener(_onLoading);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onLoading() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadPartitions();
    }
  }

  Future<void> _loadPartitions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final partitions = await ApiService.getCommunityPartitions(
        type: widget.type,
        page: _page,
        size: 20,
      );

      if (mounted) {
        setState(() {
          _partitions.addAll(partitions);
          if (partitions.isNotEmpty) {
            _page++;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        // Create a listener to sync the internal controller with the DraggableScrollableSheet's controller
        // However, DraggableScrollableSheet provides a controller that must be used by the ListView.
        // To support pagination, we need to detect scrolling on *that* controller.
        
        // NotificationListener is a better approach for DraggableScrollableSheet pagination
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!_isLoading && 
                scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              _loadPartitions();
            }
            return false;
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '选择分区',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _partitions.isEmpty && !_isLoading
                    ? const Center(child: Text('暂无分区'))
                    : ListView.separated(
                        controller: scrollController, // Must use this controller
                        itemCount: _partitions.length + 1,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == _partitions.length) {
                            return _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : const SizedBox.shrink();
                          }
                          
                          final p = _partitions[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: p.avatar.isNotEmpty
                                  ? ImageLoader.networkImageProvider(p.avatar)
                                  : null,
                              child: p.avatar.isEmpty ? const Icon(Icons.group) : null,
                            ),
                            title: Text(p.name),
                            subtitle: Text('成员: ${p.memberNum}  帖子: ${p.postNum}'),
                            onTap: () => widget.onPartitionSelected(p),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
