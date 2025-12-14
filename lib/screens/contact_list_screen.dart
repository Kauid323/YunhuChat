import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/contact_model.dart';
import '../utils/image_loader.dart';
import '../config/api_config.dart';
import 'chat_screen.dart';
import '../services/storage_service.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<AddressBookGroup> _groups = [];
  bool _isLoading = true;
  final Set<String> _expandedGroupNames = {};

  final Set<String> _avatarLoadAllowed = <String>{};
  final Queue<String> _avatarLoadQueue = Queue<String>();
  Timer? _avatarLoadTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _avatarLoadTimer?.cancel();
    _avatarLoadTimer = null;
    super.dispose();
  }

  void _enqueueAvatarLoads(AddressBookGroup group) {
    for (final item in group.items) {
      if (item.avatarUrl.isEmpty) continue;
      if (_avatarLoadAllowed.contains(item.chatId)) continue;
      if (_avatarLoadQueue.contains(item.chatId)) continue;
      _avatarLoadQueue.addLast(item.chatId);
    }

    _avatarLoadTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      var released = 0;
      while (released < 3 && _avatarLoadQueue.isNotEmpty) {
        final id = _avatarLoadQueue.removeFirst();
        _avatarLoadAllowed.add(id);
        released++;
      }
      if (mounted && released > 0) {
        setState(() {});
      }
      if (_avatarLoadQueue.isEmpty) {
        _avatarLoadTimer?.cancel();
        _avatarLoadTimer = null;
      }
    });
  }

  Future<void> _loadContacts({bool forceRemote = false}) async {
    if (!forceRemote && StorageService.hasAddressBookCache()) {
      final cached = StorageService.getAddressBookCache();
      setState(() {
        _groups = cached;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final groups = await ApiService.getAddressBookList();
      await StorageService.saveAddressBookCache(groups);
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载通讯录失败: $e')),
        );
      }
    }
  }

  int _getChatType(String listName) {
    if (listName.contains('用户')) return ChatType.user;
    if (listName.contains('群聊')) return ChatType.group;
    if (listName.contains('机器人')) return ChatType.bot;
    return ChatType.user; // Default
  }

  void _handleItemTap(AddressBookItem item, String listName) {
    final chatType = _getChatType(listName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: item.chatId,
          chatType: chatType,
          chatName: item.name,
        ),
      ),
    );
  }

  Widget _buildGroupTile(AddressBookGroup group) {
    final isExpanded = _expandedGroupNames.contains(group.listName);
    final count = group.items.length;
    if (count == 0) return const SizedBox.shrink();

    return ExpansionTile(
      key: PageStorageKey<String>('ab_${group.listName}'),
      title: Row(
        children: [
          Expanded(
            child: Text(
              group.listName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
      onExpansionChanged: (expanded) {
        if (expanded) {
          _enqueueAvatarLoads(group);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            if (expanded) {
              _expandedGroupNames.add(group.listName);
            } else {
              _expandedGroupNames.remove(group.listName);
            }
          });
        });
      },
      children: isExpanded
          ? group.items
              .map(
                (item) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        _avatarLoadAllowed.contains(item.chatId) &&
                                item.avatarUrl.isNotEmpty
                            ? ImageLoader.networkImageProvider(item.avatarUrl)
                            : null,
                    child: !_avatarLoadAllowed.contains(item.chatId) ||
                            item.avatarUrl.isEmpty
                        ? Icon(
                            _getChatType(group.listName) == ChatType.group
                                ? Icons.group
                                : Icons.person,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          )
                        : null,
                  ),
                  title: Text(item.name),
                  onTap: () => _handleItemTap(item, group.listName),
                ),
              )
              .toList()
          : <Widget>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通讯录'),
        actions: StorageService.getContactAppBarActions().map((action) {
          switch (action) {
            case 'refresh':
              return IconButton(
                onPressed: () => _loadContacts(forceRemote: true),
                icon: const Icon(Icons.refresh),
              );
            default:
              return const SizedBox.shrink();
          }
        }).toList(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadContacts(forceRemote: true),
              child: _groups.isEmpty
                  ? const Center(child: Text('暂无联系人'))
                  : ListView.builder(
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return _buildGroupTile(group);
                      },
                    ),
            ),
    );
  }
}
