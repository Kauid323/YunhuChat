import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/discover_model.dart';
import '../services/api_service.dart';
import '../utils/image_loader.dart';
import 'chat_screen.dart';

class DiscoverGroupScreen extends StatefulWidget {
  const DiscoverGroupScreen({super.key});

  @override
  State<DiscoverGroupScreen> createState() => _DiscoverGroupScreenState();
}

class _DiscoverGroupScreenState extends State<DiscoverGroupScreen> {
  final ScrollController _scrollController = ScrollController();

  List<String> _categories = <String>[];
  String _category = '精选';
  String _keyword = '';

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

  final List<DiscoverGroupItem> _groups = <DiscoverGroupItem>[];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadGroups(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (!_hasMore || _isLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadGroups(refresh: false);
    }
  }

  Future<void> _loadCategories() async {
    final list = await ApiService.getDiscoverGroupCategories();
    if (!mounted) return;
    setState(() {
      _categories = list;
      if (_categories.isNotEmpty && !_categories.contains(_category)) {
        _category = _categories.first;
      }
    });
  }

  Future<void> _loadGroups({required bool refresh}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _page = 1;
        _hasMore = true;
      }
    });

    try {
      final page = refresh ? 1 : _page;
      final result = await ApiService.getDiscoverGroupList(
        category: _category,
        keyword: _keyword,
        page: page,
        size: 30,
      );

      if (!mounted) return;
      setState(() {
        if (refresh) {
          _groups
            ..clear()
            ..addAll(result);
        } else {
          _groups.addAll(result);
        }
        _hasMore = result.length >= 30;
        _page = page + 1;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showSearchDialog() async {
    final controller = TextEditingController(text: _keyword);
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('搜索群聊'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => Navigator.of(context).pop(v),
            decoration: const InputDecoration(
              hintText: '输入关键词',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('搜索'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (value == null) return;

    setState(() {
      _keyword = value.trim();
    });
    await _loadGroups(refresh: true);
  }

  void _openChat(DiscoverGroupItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: item.chatId,
          chatType: ChatType.group,
          chatName: item.nickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.isEmpty ? 1 : _categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('发现群聊'),
          actions: [
            IconButton(
              onPressed: _showSearchDialog,
              icon: const Icon(Icons.search),
            )
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: (_categories.isEmpty ? <String>[_category] : _categories)
                .map((c) => Tab(text: c))
                .toList(),
            onTap: (index) {
              final list = _categories.isEmpty ? <String>[_category] : _categories;
              final selected = list[index];
              setState(() {
                _category = selected;
              });
              _loadGroups(refresh: true);
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadGroups(refresh: true),
          child: ListView.separated(
            controller: _scrollController,
            itemCount: _groups.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == _groups.length) {
                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              }

              final item = _groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: item.avatarUrl.isNotEmpty
                      ? ImageLoader.networkImageProvider(item.avatarUrl)
                      : null,
                  child: item.avatarUrl.isEmpty ? const Icon(Icons.group) : null,
                ),
                title: Text(item.nickname),
                subtitle: Text(item.introduction.isEmpty ? '暂无介绍' : item.introduction),
                trailing: Text('${item.headcount}人'),
                onTap: () => _openChat(item),
              );
            },
          ),
        ),
      ),
    );
  }
}
