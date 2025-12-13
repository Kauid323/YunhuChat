import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/api_service.dart';
import '../utils/image_loader.dart';

class PartitionInfoScreen extends StatefulWidget {
  final int baId;

  const PartitionInfoScreen({
    super.key,
    required this.baId,
  });

  @override
  State<PartitionInfoScreen> createState() => _PartitionInfoScreenState();
}

class _PartitionInfoScreenState extends State<PartitionInfoScreen> {
  CommunityPartition? _partitionInfo;
  final List<CommunityGroup> _groups = [];
  bool _isLoading = true;
  bool _isLoadingGroups = false;
  bool _hasMoreGroups = true;
  int _groupPage = 1;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingGroups || !_hasMoreGroups) return;
    
    // 当滚动到距离底部还有 50 像素时，自动加载更多
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 50.0;
    
    if (currentScroll + threshold >= maxScroll) {
      _loadMoreGroups();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final info = await ApiService.getPartitionInfo(baId: widget.baId);
    final groups = await ApiService.getPartitionGroups(baId: widget.baId, page: 1);
    
    if (mounted) {
      setState(() {
        _partitionInfo = info;
        _groups.addAll(groups);
        _groupPage = 2;
        _hasMoreGroups = true; // 直接设置为 true，继续加载
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreGroups() async {
    if (_isLoadingGroups || !_hasMoreGroups) return;
    
    setState(() => _isLoadingGroups = true);
    
    final groups = await ApiService.getPartitionGroups(
      baId: widget.baId,
      page: _groupPage,
    );
    
    if (mounted) {
      setState(() {
        _groups.addAll(groups);
        if (groups.isNotEmpty) {
          _groupPage++;
          _hasMoreGroups = true; // 直接设置为 true，继续加载
        } else {
          _hasMoreGroups = false;
        }
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_partitionInfo == null) return;

    final wasFollowed = _partitionInfo!.isFollowed;
    
    // 乐观更新 UI
    setState(() {
      _partitionInfo = CommunityPartition(
        id: _partitionInfo!.id,
        name: _partitionInfo!.name,
        avatar: _partitionInfo!.avatar,
        memberNum: _partitionInfo!.memberNum + (wasFollowed ? -1 : 1),
        postNum: _partitionInfo!.postNum,
        groupNum: _partitionInfo!.groupNum,
        createTimeText: _partitionInfo!.createTimeText,
        isFollowed: !wasFollowed,
      );
    });

    // 调用 API
    final success = wasFollowed
        ? await ApiService.unfollowPartition(baId: _partitionInfo!.id)
        : await ApiService.followPartition(baId: _partitionInfo!.id);

    // 如果 API 调用失败，回滚 UI
    if (!success && mounted) {
      setState(() {
        _partitionInfo = CommunityPartition(
          id: _partitionInfo!.id,
          name: _partitionInfo!.name,
          avatar: _partitionInfo!.avatar,
          memberNum: _partitionInfo!.memberNum + (wasFollowed ? 1 : -1),
          postNum: _partitionInfo!.postNum,
          groupNum: _partitionInfo!.groupNum,
          createTimeText: _partitionInfo!.createTimeText,
          isFollowed: wasFollowed,
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasFollowed ? '取消关注失败' : '关注失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('分区详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_partitionInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('分区详情')),
        body: const Center(child: Text('加载失败')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_partitionInfo!.name),
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          // 分区信息卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _partitionInfo!.avatar.isNotEmpty
                        ? ImageLoader.networkImageProvider(_partitionInfo!.avatar)
                        : null,
                    child: _partitionInfo!.avatar.isEmpty
                        ? const Icon(Icons.group, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _partitionInfo!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_partitionInfo!.createTimeText.isNotEmpty)
                    Text(
                      '创建于 ${_partitionInfo!.createTimeText}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, '成员', _partitionInfo!.memberNum),
                      _buildStatItem(context, '文章', _partitionInfo!.postNum),
                      _buildStatItem(context, '群聊', _partitionInfo!.groupNum),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 关注按钮
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _toggleFollow,
                      icon: Icon(
                        _partitionInfo!.isFollowed ? Icons.check : Icons.add,
                      ),
                      label: Text(
                        _partitionInfo!.isFollowed ? '已关注' : '关注',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _partitionInfo!.isFollowed
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: _partitionInfo!.isFollowed
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 群聊列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '绑定的群聊',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          if (_groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('暂无群聊')),
            )
          else
            ..._groups.map((group) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: group.avatarUrl.isNotEmpty
                        ? ImageLoader.networkImageProvider(group.avatarUrl)
                        : null,
                    child: group.avatarUrl.isEmpty
                        ? const Icon(Icons.group)
                        : null,
                  ),
                  title: Text(group.name),
                  subtitle: Text(
                    '${group.introduction}\n${group.category} · ${group.headcount}人',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Navigate to group detail
                  },
                )),

          if (_isLoadingGroups)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          // 显示加载状态或没有更多数据的提示
          if (!_isLoadingGroups && !_hasMoreGroups && _groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '没有更多群聊了',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
