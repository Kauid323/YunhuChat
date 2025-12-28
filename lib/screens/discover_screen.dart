import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/discover_model.dart';
import '../services/api_service.dart';
import '../utils/image_loader.dart';
import 'chat_screen.dart';
import 'discover_group_screen.dart';

/// 发现页面
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isLoading = true;
  List<DiscoverGroupItem> _groups = <DiscoverGroupItem>[];
  List<DiscoverBotItem> _bots = <DiscoverBotItem>[];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final groups = await ApiService.getDiscoverGroupList(
        category: '精选',
        keyword: '',
        size: 6,
        page: 1,
      );
      final bots = await ApiService.getDiscoverBotList();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _bots = bots;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openDiscoverGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiscoverGroupScreen()),
    );
  }

  void _openGroupChat(DiscoverGroupItem item) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('群聊', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: _openDiscoverGroup,
                    child: const Text('更多'),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '暂无群聊推荐',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              ..._groups.map((g) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: g.avatarUrl.isNotEmpty
                        ? ImageLoader.networkImageProvider(g.avatarUrl)
                        : null,
                    child: g.avatarUrl.isEmpty ? const Icon(Icons.group) : null,
                  ),
                  title: Text(g.nickname),
                  subtitle: Text(g.introduction.isEmpty ? '暂无介绍' : g.introduction),
                  trailing: Text('${g.headcount}人'),
                  onTap: () => _openGroupChat(g),
                );
              }),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('机器人', style: Theme.of(context).textTheme.titleLarge),
            ),
            if (_isLoading)
              const SizedBox.shrink()
            else if (_bots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '暂无机器人推荐',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              ..._bots.map((b) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: b.avatarUrl.isNotEmpty
                        ? ImageLoader.networkImageProvider(b.avatarUrl)
                        : null,
                    child: b.avatarUrl.isEmpty ? const Icon(Icons.smart_toy_outlined) : null,
                  ),
                  title: Text(b.nickname),
                  subtitle: Text(b.introduction.isEmpty ? '暂无介绍' : b.introduction),
                  trailing: TextButton(
                    onPressed: _openDiscoverGroup,
                    child: const Text('进入'),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

