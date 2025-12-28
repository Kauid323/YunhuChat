import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/api_service.dart';
import '../utils/image_loader.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../widgets/community_post_item.dart';
import 'my_post_list_screen.dart';
import 'partition_info_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunitySearchSheet extends StatefulWidget {
  final ValueChanged<CommunityPartition> onPartitionSelected;

  const _CommunitySearchSheet({
    required this.onPartitionSelected,
  });

  @override
  State<_CommunitySearchSheet> createState() => _CommunitySearchSheetState();
}

class _CommunitySearchSheetState extends State<_CommunitySearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<CommunityPartition> _partitions = <CommunityPartition>[];
  final List<CommunityPost> _results = <CommunityPost>[];
  bool _isLoading = false;
  String? _error;
  String _keyword = '';
  int _page = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMore && !_isLoading && _keyword.trim().isNotEmpty) {
        _search(loadMore: true);
      }
    }
  }

  Future<void> _search({bool loadMore = false}) async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;

    if (!loadMore) {
      setState(() {
        _keyword = keyword;
        _page = 1;
        _hasMore = true;
        _partitions.clear();
        _results.clear();
        _error = null;
      });
    }

    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!loadMore) {
        final result = await ApiService.searchCommunity(
          keyword: _keyword,
          page: _page,
          size: 10,
          typ: 3,
        );
        final posts = result?.posts ?? <CommunityPost>[];
        final bas = result?.partitions ?? <CommunityPartition>[];
        if (!mounted) return;
        setState(() {
          _partitions.addAll(bas);
          _results.addAll(posts);
          if (posts.isNotEmpty) {
            _page++;
          }
          _hasMore = posts.isNotEmpty;
          _isLoading = false;
        });
        return;
      }

      final posts = await ApiService.searchCommunityPosts(
        keyword: _keyword,
        page: _page,
        size: 10,
        typ: 3,
      );
      if (!mounted) return;
      setState(() {
        _results.addAll(posts);
        if (posts.isNotEmpty) {
          _page++;
        }
        _hasMore = posts.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildPartitionBlocks(BuildContext context) {
    if (_partitions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分区',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          ..._partitions.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPartitionSelected(p);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: p.avatar.isNotEmpty
                              ? ImageLoader.networkImageProvider(p.avatar)
                              : null,
                          child: p.avatar.isEmpty
                              ? const Icon(Icons.grid_view_outlined)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '成员: ${p.memberNum}  帖子: ${p.postNum}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                if (index != _partitions.length - 1) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Text(
                    '搜索',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  setState(() {});
                },
                onSubmitted: (_) => _search(loadMore: false),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: '搜索文章/分区',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results.clear();
                              _keyword = '';
                              _page = 1;
                              _hasMore = true;
                              _error = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      IconButton(
                        onPressed: _isLoading ? null : () => _search(loadMore: false),
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _keyword.isEmpty && _results.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        '输入关键词开始搜索',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            '搜索失败: $_error',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: _results.length + 2,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildPartitionBlocks(context);
                            }

                            if (index == _results.length + 1) {
                              if (_isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (_results.isEmpty && _keyword.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      '没有搜索到结果',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            return CommunityPostItem(post: _results[index - 1]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartitionInfoScreen(baId: _baId),
                ),
              );
            },
          ),
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
                  return CommunityPostItem(post: post);
                },
              ),
      ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      '更多',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCommunitySearchSheet();
                      },
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
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

  void _showCommunitySearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _CommunitySearchSheet(
          onPartitionSelected: (partition) {
            setState(() {
              _baId = partition.id;
            });
            _loadPosts(refresh: true);
          },
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
                child: Row(
                  children: [
                    Text(
                      widget.type == 3 ? '我的' : '选择分区',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
               if (widget.type == 3) // My partition specific menu
                 ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('我的文章'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyPostListScreen(),
                        ),
                      );
                    },
                 ),
               if (widget.type == 3) const Divider(height: 1),

               // Existing List
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: Row(
                   children: [
                     Text(
                       widget.type == 3 ? '我创建的分区' : '分区列表',
                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
                         color: Theme.of(context).colorScheme.primary,
                       ),
                     ),
                   ],
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
